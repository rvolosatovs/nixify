{
  self,
  crane,
  flake-utils,
  macos-sdk,
  nix-log,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
with builtins;
with nix-log.lib;
with self.lib;
with self.lib.rust;
with self.lib.rust.targets;
{
  audit ? defaultAuditConfig,
  build ? defaultBuildConfig,
  buildOverrides ? defaultBuildOverrides,
  cargoLock ? null,
  clippy ? defaultClippyConfig,
  doc ? defaultDocConfig,
  doCheck ? true,
  pkgsFor ? defaultPkgsFor,
  pname ? null,
  rustupToolchain ? defaultRustupToolchain,
  src,
  targets ? null,
  test ? defaultTestConfig,
  version ? null,
  withToolchain ? defaultWithToolchain,
}:
let
  cargoToml = readTOML "${src}/Cargo.toml";
  pname' = if pname != null then pname else pnameFromCargoToml cargoToml;

  version' =
    if version != null then
      version
    else if cargoToml.package.version.workspace or false then
      cargoToml.package.workspace.version or defaultVersion
    else
      cargoToml.package.version or defaultVersion;

  rustupToolchain' = rustupToolchain.toolchain or { };

  bins = crateBins {
    inherit
      build
      src
      ;
  };

  callCrane =
    {
      craneArgs ? { },
      craneLib,
      overrideArgs,
    }:
    f:
    let
      buildArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags build}";
      docArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags doc}";
      testArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags test}";

      clippyArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags clippy} -- ${
        with clippy;
        concatStrings (
          optionals (clippy ? allow) (map (lint: "--allow ${lint} ") allow)
          ++ optionals (clippy ? deny) (map (lint: "--deny ${lint} ") deny)
          ++ optionals (clippy ? forbid) (map (lint: "--forbid ${lint} ") forbid)
          ++ optionals (clippy ? warn) (map (lint: "--warn ${lint} ") warn)
        )
      }";

      commonArgs =
        {
          inherit
            doCheck
            src
            ;

          pname = pname';
          version = version';

          cargoBuildCommand = "cargoWithProfile build ${buildArgs}";
          cargoCheckExtraArgs = buildArgs;
          cargoClippyExtraArgs = clippyArgs;
          cargoDocExtraArgs = docArgs;
          cargoNextestExtraArgs = testArgs;
          cargoTestExtraArgs = testArgs;
        }
        // optionalAttrs (cargoLock != null) {
          inherit
            cargoLock
            ;
          cargoVendorDir = craneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // craneArgs;

      craneArgs' = commonArgs // buildOverrides overrideArgs commonArgs;
    in
    trace' "callCrane" {
      inherit
        buildArgs
        checkArgs
        clippyArgs
        docArgs
        testArgs
        ;
    } f craneArgs';

  callCraneWithDeps =
    {
      craneArgs ? { },
      craneLib,
      overrideArgs,
    }:
    let
      cargoArtifacts = callCrane {
        inherit
          craneArgs
          craneLib
          overrideArgs
          ;
      } craneLib.buildDepsOnly;
    in
    trace "callCraneWithDeps" callCrane {
      inherit
        craneLib
        overrideArgs
        ;
      craneArgs = {
        inherit cargoArtifacts;

        passthru = {
          inherit cargoArtifacts;
        } // (craneArgs.passthru or { });
      } // craneArgs;
    };

  # buildPackage builds using `craneLib`.
  buildPackage =
    {
      craneArgs ? { },
      craneLib,
      overrideArgs,
    }:
    trace "buildPackage" callCraneWithDeps {
      inherit
        craneArgs
        craneLib
        overrideArgs
        ;
    } craneLib.buildPackage;
in
final:
let
  # hostRustToolchain is the default Rust toolchain.
  hostRustToolchain = withToolchain final rustupToolchain';

  # hostCraneLib is the crane library for the host native triple.
  hostCraneLib = trace' "hostCraneLib" {
    final.stdenv.hostPlatform.config = final.stdenv.hostPlatform.config;
  } mkCraneLib final hostRustToolchain;

  mkHostArgs =
    craneArgs:
    trace' "mkHostArgs"
      {
        inherit craneArgs;
      }
      {
        inherit craneArgs;

        craneLib = hostCraneLib;

        overrideArgs.pkgs = final;
      };

  callHostCrane =
    craneArgs:
    trace' "callHostCrane" {
      inherit craneArgs;
    } callCrane (mkHostArgs craneArgs);

  callHostCraneWithDeps =
    craneArgs:
    trace' "callHostCraneWithDeps" {
      inherit craneArgs;
    } callCraneWithDeps (mkHostArgs craneArgs);

  callHostCraneCheckWithDeps =
    craneArgs:
    trace' "callHostCraneCheckWithDeps"
      {
        inherit craneArgs;
      }
      callHostCraneWithDeps
      (
        craneArgs
        // {
          doCheck = true; # without performing the actual testing, this check is useless
        }
      );

  checks =
    {
      clippy = callHostCraneWithDeps { } hostCraneLib.cargoClippy;
      doc = callHostCraneWithDeps { } hostCraneLib.cargoDoc;
      fmt = callHostCrane { } hostCraneLib.cargoFmt;
      nextest = callHostCraneCheckWithDeps { } hostCraneLib.cargoNextest;
    }
    // (optionalAttrs (test ? doc && test.doc || test ? allTargets && test.allTargets)) {
      doctest = callHostCraneCheckWithDeps {
        cargoTestExtraArgs = "-j $NIX_BUILD_CORES ${
          mkCargoFlags (
            test
            // {
              allTargets = false;
            }
          )
        }";
      } hostCraneLib.cargoDocTest;
    }
    // (optionalAttrs (pathExists "${src}/Cargo.lock") {
      # TODO: Use `cargoLock` if `Cargo.lock` missing
      audit = callHostCrane {
        advisory-db = audit.database;
      } hostCraneLib.cargoAudit;
    });

  buildHostPackage =
    craneArgs:
    trace' "buildHostPackage"
      {
        inherit craneArgs;
      }
      callHostCraneWithDeps
      (
        craneArgs
        // {
          nativeBuildInputs = [
            final.removeReferencesTo
          ] ++ optional final.stdenv.hostPlatform.isDarwin final.darwin.autoSignDarwinBinariesHook;

          postInstall = ''
            find "$out" -type f -exec remove-references-to \
              -t ${hostRustToolchain} \
              '{}' +
          '';
        }
      )
      hostCraneLib.buildPackage;

  hostBin = buildHostPackage commonReleaseArgs;
  hostDebugBin = buildHostPackage commonDebugArgs;

  mkPackages =
    prev:
    let
      rustupToolchainTargets = rustupToolchain'.targets or [ ];

      rustupToolchainWithTarget =
        target:
        trace' "rustupToolchainWithTarget"
          {
            inherit target;
          }
          (
            if any (eq target) rustupToolchainTargets then
              rustupToolchain'
            else if target == aarch64-apple-darwin && prev.stdenv.buildPlatform.system == aarch64-darwin then
              rustupToolchain'
            else if
              target == aarch64-unknown-linux-gnu && prev.stdenv.buildPlatform.system == aarch64-linux
            then
              rustupToolchain'
            else if target == x86_64-apple-darwin && prev.stdenv.buildPlatform.system == x86_64-darwin then
              rustupToolchain'
            else if target == x86_64-pc-windows-gnu && prev.stdenv.buildPlatform.system == x86_64-windows then
              rustupToolchain'
            else if target == x86_64-unknown-linux-gnu && prev.stdenv.buildPlatform.system == x86_64-linux then
              rustupToolchain'
            else
              rustupToolchain'
              // {
                targets = rustupToolchainTargets ++ [ target ];
              }
          );

      rustToolchainFor =
        target:
        let
          rustupToolchain = rustupToolchainWithTarget target;
        in
        trace' "rustupToolchainFor" {
          inherit target;
        } withToolchain final rustupToolchain;

      # buildPackageFor builds for `target`.
      # `extraArgs` are passed through to `buildPackage` verbatim.
      # NOTE: Upstream only provides binary caches for a subset of supported systems.
      buildPackageFor =
        {
          craneArgs,
          craneLib,
          pkgsCross,
          rustToolchain,
          target,
        }:
        let
          kebab2snake = replaceStrings [ "-" ] [ "_" ];

          useRosetta =
            final.stdenv.buildPlatform.isDarwin
            && final.stdenv.buildPlatform.isAarch64
            && pkgsCross.stdenv.hostPlatform.isDarwin
            && pkgsCross.stdenv.hostPlatform.isx86_64;
          useEmu =
            final.stdenv.buildPlatform.system != pkgsCross.stdenv.hostPlatform.system
            && !useRosetta
            && !pkgsCross.stdenv.hostPlatform.isDarwin;

          crossZigCC =
            let
              target' =
                if target == aarch64-apple-darwin then
                  "aarch64-macos"
                else if target == aarch64-apple-ios then
                  "aarch64-ios"
                else if target == x86_64-apple-darwin then
                  "x86_64-macos"
                else
                  throw "unsupported target ${target}";
            in
            # NOTE: Prior art:
            # https://actually.fyi/posts/zig-makes-rust-cross-compilation-just-work
            # https://github.com/rust-cross/cargo-zigbuild
            final.writeShellScriptBin "${target}-zigcc" ''
              ${final.zig}/bin/zig cc ${optionalString pkgsCross.stdenv.buildPlatform.isDarwin ''--sysroot="$SDKROOT" -I"$SDKROOT/usr/include" -L"$SDKROOT/usr/lib" -F"$SDKROOT/System/Library/Frameworks"''} $@ -target ${target'}
            '';

          targetArgs =
            {
              HOST_AR = "${final.stdenv.cc.targetPrefix}ar";
              HOST_CC = "${final.stdenv.cc.targetPrefix}cc";

              CARGO_BUILD_TARGET = target;
            }
            // (
              if
                pkgsCross.stdenv.hostPlatform.isDarwin
              # Use `rust-lld` linker and Zig C compiler for Darwin targets
              then
                {
                  # Removing vendor references here:
                  # - invalidates the signature, which is required on aarch64-darwin
                  # - fails on Darwin dylibs starting with Rust 1.79
                  doNotRemoveReferencesToVendorDir = true;

                  depsBuildBuild = [
                    crossZigCC
                  ];

                  preBuild = ''
                    export HOME=$(mktemp -d)
                    export SDKROOT="${macos-sdk}"
                  '';

                  "CC_${target}" = "${target}-zigcc";

                  "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "rust-lld";
                }
              else
                (
                  {
                    disallowedReferences = [
                      pkgsCross.stdenv.cc
                    ] ++ optional pkgsCross.stdenv.hostPlatform.isWindows pkgsCross.windows.pthreads;

                    depsBuildBuild = [
                      pkgsCross.stdenv.cc
                    ] ++ optional pkgsCross.stdenv.hostPlatform.isWindows pkgsCross.windows.pthreads;

                    nativeBuildInputs = [
                      final.removeReferencesTo
                    ];

                    postInstall = ''
                      find "$out" -type f -exec remove-references-to \
                        -t ${pkgsCross.stdenv.cc} \
                        -t ${rustToolchain} \
                         ${optionalString pkgsCross.stdenv.hostPlatform.isWindows "-t ${pkgsCross.windows.pthreads}"} \
                        '{}' +
                    '';

                    "AR_${target}" = "${pkgsCross.stdenv.cc.targetPrefix}ar";
                    "CC_${target}" = "${pkgsCross.stdenv.cc.targetPrefix}cc";
                  }
                  # Use `mold` linker for Linux targets
                  // optionalAttrs pkgsCross.stdenv.hostPlatform.isLinux {
                    nativeBuildInputs = [
                      final.mold
                      final.removeReferencesTo
                    ];

                    "CARGO_TARGET_${toUpper (kebab2snake target)}_RUSTFLAGS" = "-Clink-arg=-fuse-ld=mold";
                  }
                  # Always build static binaries for Windows targets
                  // optionalAttrs pkgsCross.stdenv.hostPlatform.isWindows {
                    "CARGO_TARGET_${toUpper (kebab2snake target)}_RUSTFLAGS" = "-Ctarget-feature=+crt-static";
                  }
                  # Use default linker for Wasm targets
                  // optionalAttrs (!pkgsCross.stdenv.hostPlatform.isWasm) {
                    "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "${pkgsCross.stdenv.cc.targetPrefix}cc";
                  }
                )
            )
            // optionalAttrs (final.stdenv.buildPlatform.config != pkgsCross.stdenv.hostPlatform.config) (
              {
                strictDeps = true;

                nativeCheckInputs = optional useEmu (
                  if pkgsCross.stdenv.hostPlatform.isWasm then
                    final.wasmtime
                  else if pkgsCross.stdenv.hostPlatform.isWindows then
                    final.wine64
                  else
                    final.qemu
                );
              }
              // optionalAttrs (doCheck && target == aarch64-apple-darwin) {
                doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;
              }
              //
                optionalAttrs
                  (doCheck && pkgsCross.stdenv.hostPlatform.isDarwin && !final.stdenv.buildPlatform.isDarwin)
                  {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` from non-Darwin platform" false;
                  }
              // optionalAttrs (doCheck && useEmu) (
                if target == arm-unknown-linux-gnueabihf then
                  {
                    CARGO_TARGET_ARM_UNKNOWN_LINUX_GNUEABIHF_RUNNER = "qemu-arm";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == arm-unknown-linux-musleabihf then
                  {
                    CARGO_TARGET_ARM_UNKNOWN_LINUX_MUSLEABIHF_RUNNER = "qemu-arm";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == armv7-unknown-linux-gnueabihf then
                  {
                    CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_RUNNER = "qemu-arm";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == armv7-unknown-linux-musleabihf then
                  {
                    CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_RUNNER = "qemu-arm";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == aarch64-linux-android then
                  {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;
                  }
                else if target == aarch64-unknown-linux-gnu then
                  {
                    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == aarch64-unknown-linux-musl then
                  {
                    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-aarch64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == mips-unknown-linux-gnu then
                  {
                    CARGO_TARGET_MIPS_UNKNOWN_LINUX_GNU_RUNNER = "qemu-mips";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == mips64-unknown-linux-gnuabi64 then
                  {
                    CARGO_TARGET_MIPS64_UNKNOWN_LINUX_GNUABI64_RUNNER = "qemu-mips64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == mips64el-unknown-linux-gnuabi64 then
                  {
                    CARGO_TARGET_MIPS64EL_UNKNOWN_LINUX_GNUABI64_RUNNER = "qemu-mips64el";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == mipsel-unknown-linux-gnu then
                  {
                    CARGO_TARGET_MIPSEL_UNKNOWN_LINUX_GNU_RUNNER = "qemu-mipsel";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == powerpc64-unknown-linux-gnu then
                  {
                    CARGO_TARGET_POWERPC64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-ppc64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == powerpc64-unknown-linux-musl then
                  {
                    CARGO_TARGET_POWERPC64_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-ppc64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == powerpc64le-unknown-linux-gnu then
                  {
                    CARGO_TARGET_POWERPC64LE_UNKNOWN_LINUX_GNU_RUNNER = "qemu-ppc64le";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == powerpc64le-unknown-linux-musl then
                  {
                    CARGO_TARGET_POWERPC64LE_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-ppc64le";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == riscv64gc-unknown-linux-gnu then
                  {
                    CARGO_TARGET_RISCV64GC_UNKNOWN_LINUX_GNU_RUNNER = "qemu-riscv64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == s390x-unknown-linux-gnu then
                  {
                    CARGO_TARGET_S390X_UNKNOWN_LINUX_GNU_RUNNER = "qemu-s390x";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == wasm32-unknown-unknown then
                  {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;
                  }
                else if target == wasm32-wasip1 then
                  {
                    CARGO_TARGET_WASM32_WASIP1_RUNNER = "wasmtime run -C cache=n";
                  }
                else if target == wasm32-wasip2 then
                  {
                    CARGO_TARGET_WASM32_WASIP2_RUNNER = "wasmtime run -C cache=n";
                  }
                else if target == x86_64-unknown-linux-gnu then
                  {
                    CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-x86_64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == x86_64-unknown-linux-musl then
                  {
                    CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-x86_64";
                  }
                  // optionalAttrs final.stdenv.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == x86_64-pc-windows-gnu then
                  {
                    # TODO: This works locally, but for some reason does not within the sanbox
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;

                    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = final.writeScript "wine-wrapper" ''
                      export WINEPREFIX="$(mktemp -d)"
                      exec wine64 $@
                    '';
                  }
                else
                  warn
                    "do not know which test runner to use for target `${target}`, set `CARGO_TARGET_${toUpper (kebab2snake target)}_RUNNER` to appropriate `qemu` binary name"
                    { }
              )
            );
        in
        trace' "buildPackageFor"
          {
            inherit
              craneArgs
              target
              useRosetta
              useEmu
              ;
            final.stdenv.buildPlatform.config = final.stdenv.buildPlatform.config;
            pkgsCross.stdenv.hostPlatform.config = pkgsCross.stdenv.hostPlatform.config;
          }
          buildPackage
          {
            inherit
              craneLib
              ;

            overrideArgs = {
              inherit
                pkgsCross
                target
                ;
              pkgs = final;
            };
            craneArgs = targetArgs // craneArgs;
          };

      targets' =
        let
          default.${aarch64-apple-darwin} = true;
          default.${aarch64-apple-ios} = false;
          default.${aarch64-linux-android} =
            prev.stdenv.hostPlatform.isLinux && prev.stdenv.hostPlatform.isx86_64;
          default.${aarch64-unknown-linux-gnu} = true;
          default.${aarch64-unknown-linux-musl} = true;
          default.${arm-unknown-linux-gnueabi} = false;
          default.${arm-unknown-linux-gnueabihf} = true;
          default.${arm-unknown-linux-musleabi} = false;
          default.${arm-unknown-linux-musleabihf} = true;
          default.${armv7-unknown-linux-gnueabi} = false;
          default.${armv7-unknown-linux-gnueabihf} = true;
          default.${armv7-unknown-linux-musleabi} = false;
          default.${armv7-unknown-linux-musleabihf} = true;
          default.${armv7s-apple-ios} = false;
          default.${mips-unknown-linux-gnu} = false;
          default.${mips-unknown-linux-musl} = false;
          default.${mips64-unknown-linux-gnuabi64} = false;
          default.${mips64-unknown-linux-muslabi64} = false;
          default.${mips64el-unknown-linux-gnuabi64} = false;
          default.${mips64el-unknown-linux-muslabi64} = false;
          default.${mipsel-unknown-linux-gnu} = false;
          default.${mipsel-unknown-linux-musl} = false;
          default.${powerpc-unknown-linux-gnu} = false;
          default.${powerpc-unknown-linux-musl} = false;
          default.${powerpc64-unknown-linux-gnu} = false;
          default.${powerpc64-unknown-linux-musl} = false;
          default.${powerpc64le-unknown-linux-gnu} = true;
          default.${powerpc64le-unknown-linux-musl} = false;
          default.${riscv64gc-unknown-linux-gnu} = true;
          default.${riscv64gc-unknown-linux-musl} = false;
          default.${s390x-unknown-linux-gnu} = true;
          default.${s390x-unknown-linux-musl} = false;
          default.${wasm32-unknown-unknown} = true;
          default.${wasm32-wasip1} = false;
          default.${wasm32-wasip2} = true;
          default.${x86_64-apple-darwin} = true;
          default.${x86_64-apple-ios} = false;
          default.${x86_64-pc-windows-gnu} = true;
          default.${x86_64-unknown-linux-gnu} = true;
          default.${x86_64-unknown-linux-musl} = true;

          selected = default // optionalAttrs (targets != null) targets;
        in
        mapAttrs' (
          target: enabled:
          warnIf (enabled && !(default ? ${target})) ''
            target `${target}` is not supported
            set `targets.${target} = false` to remove this warning'' (nameValuePair target enabled)
        ) selected;

      targetBins =
        let
          mkOutputs =
            target:
            let
              pkgsCross = pkgsFor final target;
              rustToolchain = rustToolchainFor target;
              craneLib = mkCraneLib final rustToolchain;

              withPassthru =
                craneArgs:
                {
                  passthru ? { },
                  ...
                }@pkg:
                pkg
                // {
                  passthru =
                    passthru
                    // {
                      inherit
                        pkgsCross
                        rustToolchain
                        target
                        ;
                    }
                    // optionalAttrs (craneArgs ? CARGO_PROFILE) {
                      inherit (craneArgs)
                        CARGO_PROFILE
                        ;
                    };
                };

              buildPackageFor' =
                craneArgs:
                let
                  pkg = buildPackageFor {
                    inherit
                      craneArgs
                      craneLib
                      pkgsCross
                      rustToolchain
                      target
                      ;
                  };
                in
                withPassthru craneArgs pkg;
            in
            optionalAttrs (targets' ? ${target} && targets'.${target}) {
              "${pname'}-${target}" = buildPackageFor' commonReleaseArgs;
              "${pname'}-debug-${target}" = buildPackageFor' commonDebugArgs;
            };
          packages = map mkOutputs (attrValues rust.targets);
        in
        foldr mergeAttrs { } packages;

      targetDeps = mapAttrs' (name: bin: nameValuePair "${name}-deps" bin.cargoArtifacts) targetBins;

      # https://github.com/docker-library/official-images#architectures-other-than-amd64
      # https://go.dev/doc/install/source#environment
      # https://github.com/docker-library/bashbrew/blob/7e160dca3123caecf32c33ba31821dd2aa3716cd/architecture/oci-platform.go#L14-L27
      # TODO: Update `buildImage` to support setting a platform struct
      #ociArchitecture.${aarch64-apple-darwin} = "darwin-arm64v8";
      #ociArchitecture.${aarch64-unknown-linux-gnu} = "arm64v8";
      #ociArchitecture.${aarch64-unknown-linux-musl} = "arm64v8";
      #ociArchitecture.${armv7-unknown-linux-musleabihf} = "arm32v7";
      #ociArchitecture.${x86_64-apple-darwin} = "darwin-amd64";
      #ociArchitecture.${x86_64-pc-windows-gnu} = "windows-amd64";
      ociArchitecture.${aarch64-apple-darwin} = "arm64";
      ociArchitecture.${aarch64-linux-android} = "arm64";
      ociArchitecture.${aarch64-unknown-linux-gnu} = "arm64";
      ociArchitecture.${aarch64-unknown-linux-musl} = "arm64";
      ociArchitecture.${armv7-unknown-linux-musleabihf} = "arm";
      ociArchitecture.${wasm32-unknown-unknown} = "wasm";
      ociArchitecture.${wasm32-wasip1} = "wasm";
      ociArchitecture.${wasm32-wasip2} = "wasm";
      ociArchitecture.${x86_64-apple-darwin} = "amd64";
      ociArchitecture.${x86_64-pc-windows-gnu} = "amd64";
      ociArchitecture.${x86_64-unknown-linux-gnu} = "amd64";
      ociArchitecture.${x86_64-unknown-linux-musl} = "amd64";

      bins' = genAttrs bins (_: { });
      targetImages = (
        mapAttrs' (
          target: pkg:
          let
            img = final.dockerTools.buildImage (
              {
                name = pname';
                tag = "${version'}-${pkg.passthru.target}";
                copyToRoot = final.buildEnv {
                  name = pname';
                  paths = [ pkg ];
                };
                config.Env = [ "PATH=${pkg}/bin" ];
              }
              // optionalAttrs (bins' ? ${pname'}) {
                config.Cmd = [ pname' ];
              }
              // optionalAttrs (length bins == 1) {
                config.Cmd = bins;
              }
              // optionalAttrs (ociArchitecture ? ${pkg.passthru.target}) {
                architecture = ociArchitecture.${pkg.passthru.target};
              }
            );
          in
          nameValuePair "${target}-oci" (
            img
            // {
              passthru = pkg.passthru // img.passthru;
            }
          )
        ) targetBins
      );

      multiArchTargets = [
        aarch64-unknown-linux-musl
        armv7-unknown-linux-musleabihf
        #x86_64-pc-windows-gnu # TODO: Re-enable once we can set OS
        x86_64-unknown-linux-musl
      ];
    in
    {
      "${pname'}" = hostBin;
      "${pname'}-debug" = hostDebugBin;
    }
    // targetDeps
    // targetBins
    // targetImages
    // optionalAttrs (any (target: targetImages ? "${pname'}-${target}-oci") multiArchTargets) {
      "build-${pname'}-oci" =
        let
          build = final.writeShellScriptBin "build-${pname'}-oci" ''
            set -xe

            build() {
              ${final.buildah}/bin/buildah manifest create "''${1}"
              ${concatMapStringsSep "\n" (
                target:
                let
                  name = "${pname'}-${target}-oci";
                in
                optionalString (targetImages ? ${name}) ''
                  ${final.buildah}/bin/buildah manifest add "''${1}" docker-archive:${targetImages."${name}"}
                  ${final.buildah}/bin/buildah pull docker-archive:${targetImages."${name}"}
                ''
              ) multiArchTargets}
            }
            build "''${1:-${pname'}:${version'}}"
          '';
        in
        (
          build
          // {
            inherit
              version
              ;
          }
        );
    };

  packages = mkPackages final;
in
{
  inherit
    buildHostPackage
    callCrane
    callCraneWithDeps
    callHostCrane
    callHostCraneWithDeps
    checks
    hostCraneLib
    hostRustToolchain
    packages
    ;
  overlay = mkPackages;
}
