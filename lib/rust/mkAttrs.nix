{
  self,
  crane,
  flake-utils,
  nixlib,
  nix-log,
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
  }: let
    cargoToml = readTOML "${src}/Cargo.toml";
    pname' =
      if pname != null
      then pname
      else pnameFromCargoToml cargoToml;

    version' =
      if version != null
      then version
      else cargoToml.package.version or defaultVersion;

    rustupToolchain' = rustupToolchain.toolchain or {};

    bins = crateBins {
      inherit
        build
        src
        ;
    };
    isLib = length bins == 0;

    callCrane = {
      craneArgs ? {},
      craneLib,
      overrideArgs,
    }: f: let
      buildArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags build}";
      checkArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags build}";
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
          cargoCheckExtraArgs = checkArgs;
          cargoClippyExtraArgs = clippyArgs;
          cargoDocExtraArgs = docArgs;
          cargoNextestExtraArgs = testArgs;
          cargoTestExtraArgs = testArgs;

          installCargoArtifactsMode = "use-zstd";
        }
        // optionalAttrs (cargoLock != null) {
          cargoVendorDir = craneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // craneArgs;

      craneArgs' =
        commonArgs // buildOverrides overrideArgs commonArgs;
    in
      trace' "callCrane" {
        inherit
          buildArgs
          checkArgs
          clippyArgs
          docArgs
          testArgs
          ;
      }
      f
      craneArgs';

    callCraneWithDeps = {
      craneArgs ? {},
      craneLib,
      overrideArgs,
    } @ args:
      trace' "callCraneWithDeps" {
        inherit craneArgs;
      }
      callCrane {
        inherit
          craneLib
          overrideArgs
          ;
        craneArgs =
          {
            cargoArtifacts =
              callCrane {
                inherit
                  craneLib
                  overrideArgs
                  ;
                craneArgs = filterAttrs (name: _: name != "installPhaseCommand") craneArgs;
              }
              craneLib.buildDepsOnly;
          }
          // craneArgs;
      };

    # buildPackage builds using `craneLib`.
    buildPackage = {
      craneArgs ? {},
      craneLib,
      overrideArgs,
    }:
      trace' "buildPackage" {
        inherit
          craneArgs
          ;
      }
      callCraneWithDeps {
        inherit
          craneLib
          overrideArgs
          ;

        craneArgs =
          optionalAttrs (!isLib) {
            installPhaseCommand = ''
              if [ "''${CARGO_PROFILE}" == 'dev' ]; then
                  profileDir=debug
              else
                  profileDir=''${CARGO_PROFILE:-debug}
              fi
              ${concatMapStringsSep "\n" (name: ''
                  case ''${CARGO_BUILD_TARGET} in
                      ${wasm32-wasi})
                          install -D target/${wasm32-wasi}/''${profileDir}/${name}.wasm $out/bin/${name};;
                      ${x86_64-pc-windows-gnu})
                          install -D target/${x86_64-pc-windows-gnu}/''${profileDir}/${name}.exe $out/bin/${name}.exe;;
                      "")
                          install -D target/''${profileDir}/${name} $out/bin/${name};;
                      *)
                          install -D target/''${CARGO_BUILD_TARGET}/''${profileDir}/${name} $out/bin/${name};;
                  esac
                '')
                bins}
            '';
          }
          // craneArgs;
      }
      craneLib.buildPackage;
  in
    final: let
      # hostRustToolchain is the default Rust toolchain.
      hostRustToolchain = withToolchain final rustupToolchain';

      # hostCraneLib is the crane library for the host native triple.
      hostCraneLib =
        trace' "hostCraneLib" {
          final.hostPlatform.config = final.hostPlatform.config;
        }
        mkCraneLib
        final
        hostRustToolchain;

      mkHostArgs = {depsBuildBuild ? [], ...} @ craneArgs:
        trace' "mkHostArgs" {
          inherit craneArgs;
        }
        {
          craneArgs =
            craneArgs
            // {
              depsBuildBuild = depsBuildBuild ++ optional final.hostPlatform.isDarwin final.darwin.apple_sdk.frameworks.Security;
            };
          craneLib = hostCraneLib;

          overrideArgs.pkgs = final;
        };

      callHostCrane = craneArgs:
        trace' "callHostCrane" {
          inherit craneArgs;
        }
        callCrane (mkHostArgs craneArgs);

      callHostCraneWithDeps = craneArgs:
        trace' "callHostCraneWithDeps" {
          inherit craneArgs;
        }
        callCraneWithDeps (mkHostArgs craneArgs);

      checks.clippy = callHostCraneWithDeps {} hostCraneLib.cargoClippy;
      checks.doc = callHostCraneWithDeps {} hostCraneLib.cargoDoc;
      checks.fmt = callHostCrane {} hostCraneLib.cargoFmt;
      checks.nextest =
        callHostCraneWithDeps {
          doCheck = true; # without performing the actual testing, this check is useless
        }
        hostCraneLib.cargoNextest;

      buildHostPackage = craneArgs:
        trace' "buildHostPackage" {
          inherit craneArgs;
        }
        callHostCraneWithDeps
        craneArgs
        hostCraneLib.buildPackage;

      hostBin = buildHostPackage commonReleaseArgs;
      hostDebugBin = buildHostPackage commonDebugArgs;

      mkPackages = prev: let
        rustupToolchainTargets = rustupToolchain'.targets or [];

        rustupToolchainWithTarget = target:
          trace' "rustupToolchainWithTarget" {
            inherit target;
          }
          (
            if any (eq target) rustupToolchainTargets
            then rustupToolchain'
            else if target == aarch64-apple-darwin && prev.buildPlatform.system == aarch64-darwin
            then rustupToolchain'
            else if target == x86_64-apple-darwin && prev.buildPlatform.system == x86_64-darwin
            then rustupToolchain'
            else if target == x86_64-pc-windows-gnu && prev.buildPlatform.system == x86_64-pc-windows-gnu
            then rustupToolchain'
            else
              rustupToolchain'
              // {
                targets = rustupToolchainTargets ++ [target];
              }
          );

        rustToolchainFor = target: let
          rustupToolchain = rustupToolchainWithTarget target;
        in
          trace' "rustupToolchainFor" {
            inherit target;
          }
          withToolchain
          final
          rustupToolchain;

        # buildPackageFor builds for `target`.
        # `extraArgs` are passed through to `buildPackage` verbatim.
        # NOTE: Upstream only provides binary caches for a subset of supported systems.
        buildPackageFor = target: craneArgs: let
          kebab2snake = replaceStrings ["-"] ["_"];
          rustToolchain = rustToolchainFor target;
          craneLib = mkCraneLib final rustToolchain;
          pkgsCross = pkgsFor final target;

          useRosetta = pkgsCross.buildPlatform.system == aarch64-darwin && pkgsCross.hostPlatform.system == x86_64-darwin;
          useEmu = pkgsCross.buildPlatform.system != pkgsCross.hostPlatform.system && !useRosetta && pkgsCross.hostPlatform.system != aarch64-darwin;

          depsBuildBuild = optional pkgsCross.hostPlatform.isDarwin pkgsCross.darwin.apple_sdk.frameworks.Security;

          targetArgs =
            {
              inherit
                depsBuildBuild
                ;

              CARGO_BUILD_TARGET = target;

              RUSTFLAGS = "-C target-feature=+crt-static";
            }
            // optionalAttrs (pkgsCross.buildPlatform.config != pkgsCross.hostPlatform.config) (
              {
                strictDeps = true;

                depsBuildBuild =
                  depsBuildBuild
                  ++ [
                    pkgsCross.stdenv.cc
                  ]
                  ++ optional pkgsCross.hostPlatform.isWindows pkgsCross.windows.pthreads;

                checkInputs = optional useEmu (
                  if pkgsCross.hostPlatform.isWasm
                  then final.wasmtime
                  else if pkgsCross.hostPlatform.isWindows
                  then final.wine64
                  else final.qemu
                );

                HOST_AR = "${final.stdenv.cc.targetPrefix}ar";
                HOST_CC = "${final.stdenv.cc.targetPrefix}cc";

                "AR_${target}" = "${pkgsCross.stdenv.cc.targetPrefix}ar";
                "CC_${target}" = "${pkgsCross.stdenv.cc.targetPrefix}cc";
              }
              // optionalAttrs (!pkgsCross.hostPlatform.isWasi) {
                "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "${pkgsCross.stdenv.cc.targetPrefix}cc";
              }
              // optionalAttrs (doCheck && target == aarch64-apple-darwin) {
                doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;
              }
              // optionalAttrs (doCheck && useEmu) (
                if target == armv7-unknown-linux-musleabihf
                then
                  {
                    CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_RUNNER = "qemu-arm";
                  }
                  // optionalAttrs pkgsCross.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == aarch64-unknown-linux-musl
                then
                  {
                    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-aarch64";
                  }
                  // optionalAttrs pkgsCross.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == wasm32-wasi
                then {
                  CARGO_TARGET_WASM32_WASI_RUNNER = "wasmtime --disable-cache";
                }
                else if target == x86_64-unknown-linux-musl
                then
                  {
                    CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUNNER = "qemu-x86_64";
                  }
                  // optionalAttrs pkgsCross.buildPlatform.isDarwin {
                    doCheck = warn "testing not currently supported when cross-compiling for `${target}` on Darwin" false;
                  }
                else if target == x86_64-pc-windows-gnu
                then {
                  # TODO: This works locally, but for some reason does not within the sanbox
                  doCheck = warn "testing not currently supported when cross-compiling for `${target}`" false;

                  CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = final.writeScript "wine-wrapper" ''
                    export WINEPREFIX="$(mktemp -d)"
                    exec wine64 $@
                  '';
                }
                else warn "do not know which test runner to use for target `${target}`, set `CARGO_TARGET_${toUpper (kebab2snake target)}_RUNNER` to appropriate `qemu` binary name" {}
              )
            );
        in
          trace' "buildPackageFor" {
            inherit
              craneArgs
              target
              useRosetta
              useEmu
              ;
            pkgsCross.buildPlatform.config = pkgsCross.buildPlatform.config;
            pkgsCross.hostPlatform.config = pkgsCross.hostPlatform.config;
          }
          buildPackage {
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

        targets' = let
          default.${aarch64-apple-darwin} = prev.hostPlatform.isDarwin;
          default.${aarch64-unknown-linux-musl} = true;
          default.${armv7-unknown-linux-musleabihf} = true;
          default.${wasm32-wasi} = true;
          default.${x86_64-apple-darwin} = prev.hostPlatform.system == x86_64-darwin;
          default.${x86_64-pc-windows-gnu} = true;
          default.${x86_64-unknown-linux-musl} = true;

          all =
            default
            // optionalAttrs (targets != null) targets;
        in
          mapAttrs' (target: enabled:
            warnIf (enabled && !(default ? ${target})) ''
              target `${target}` is not supported
              set `targets.${target} = false` to remove this warning'' (nameValuePair target enabled))
          all;

        targetBins = let
          mkPackages = target:
            optionalAttrs targets'.${target} {
              "${pname'}-${target}" = buildPackageFor target commonReleaseArgs;
              "${pname'}-debug-${target}" = buildPackageFor target commonDebugArgs;
            };
          packages = map mkPackages (attrValues rust.targets);
        in
          foldr mergeAttrs {} packages;

        bins' = genAttrs bins (_: {});
        targetImages = optionalAttrs (bins' ? ${pname'}) (mapAttrs' (target: bin:
          nameValuePair "${target}-oci" (final.dockerTools.buildImage {
            name = pname';
            tag = version';
            copyToRoot = final.buildEnv {
              name = pname';
              paths = [bin];
            };
            config.Cmd = [pname'];
            config.Env = ["PATH=${bin}/bin"];
          }))
        targetBins);
      in
        {
          "${pname'}" = hostBin;
          "${pname'}-debug" = hostDebugBin;
        }
        // targetBins
        // targetImages;

      packages = mkPackages final;
    in
      {
        inherit
          buildHostPackage
          callCrane
          callCraneWithDeps
          callHostCrane
          callHostCraneWithDeps
          hostCraneLib
          hostRustToolchain
          ;
      }
      // optionalAttrs isLib {
        checks = checks // packages;
      }
      // optionalAttrs (!isLib) {
        inherit
          checks
          packages
          ;
        overlay = mkPackages;
      }
