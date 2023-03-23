{
  self,
  crane,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
with builtins;
with self.lib;
with self.lib.rust;
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

    # commonArgs is a set of arguments that is common to all crane invocations.
    commonArgs = let
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
    in {
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
    };

    # buildPackage builds using `craneLib`.
    # `extraArgs` are passed through to `craneLib.buildPackage` verbatim.
    buildPackage = craneLib: extraArgs:
      craneLib.buildPackage (
        commonArgs
        // optionalAttrs (!isLib) {
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
                    "")
                        install -D target/''${profileDir}/${name} $out/bin/${name};;
                    *)
                        install -D target/''${CARGO_BUILD_TARGET}/''${profileDir}/${name} $out/bin/${name};;
                esac
              '')
              bins}
          '';
        }
        // optionalAttrs (cargoLock != null) {
          cargoVendorDir = craneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // extraArgs
      );
  in
    final: let
      # hostRustToolchain is the default Rust toolchain.
      hostRustToolchain = withToolchain final rustupToolchain';

      # hostCraneLib is the crane library for the host native triple.
      hostCraneLib = mkCraneLib final hostRustToolchain;

      commonOverrideArgs =
        commonArgs
        // {
          pkgs = final;
        };

      hostBuildOverrides = buildOverrides commonOverrideArgs;

      # buildDeps builds dependencies of the crate given `craneLib`.
      # `extraArgs` are passed through to `craneLib.buildDepsOnly` verbatim.
      buildDeps = craneLib: extraArgs:
        craneLib.buildDepsOnly (
          commonArgs
          // optionalAttrs (cargoLock != null) {
            cargoVendorDir = craneLib.vendorCargoDeps {
              inherit
                cargoLock
                src
                ;
            };
          }
          // extraArgs
          // hostBuildOverrides
        );

      buildHostCargoArtifacts = buildDeps hostCraneLib;

      # hostCargoArtifacts are the cargo artifacts built for the host native triple.
      hostCargoArtifacts = buildHostCargoArtifacts {};

      buildHostPackage = extraArgs:
        buildPackage hostCraneLib (
          {
            cargoArtifacts = buildHostCargoArtifacts extraArgs;
          }
          // extraArgs
          // hostBuildOverrides
        );

      checks.clippy = hostCraneLib.cargoClippy (
        commonArgs
        // {
          cargoArtifacts = hostCargoArtifacts;
        }
        // optionalAttrs (cargoLock != null) {
          cargoVendorDir = hostCraneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // hostBuildOverrides
      );
      checks.doc = hostCraneLib.cargoDoc (
        commonArgs
        // {
          cargoArtifacts = hostCargoArtifacts;
        }
        // optionalAttrs (cargoLock != null) {
          cargoVendorDir = hostCraneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // hostBuildOverrides
      );
      checks.fmt = hostCraneLib.cargoFmt (
        commonArgs
        // hostBuildOverrides
      );
      checks.nextest = hostCraneLib.cargoNextest (
        commonArgs
        // {
          cargoArtifacts = hostCargoArtifacts;

          doCheck = true; # without performing the actual testing, this check is useless
        }
        // optionalAttrs (cargoLock != null) {
          cargoVendorDir = hostCraneLib.vendorCargoDeps {
            inherit
              cargoLock
              src
              ;
          };
        }
        // hostBuildOverrides
      );

      hostBin = buildHostPackage commonReleaseArgs;
      hostDebugBin = buildHostPackage commonDebugArgs;

      mkPackages = prev: let
        rustupToolchainTargets = rustupToolchain'.targets or [];

        rustupToolchainWithTarget = target:
          if any (eq target) rustupToolchainTargets
          then rustupToolchain'
          else if target == "aarch64-apple-darwin" && prev.hostPlatform.system == aarch64-darwin
          then rustupToolchain'
          else if target == "x86_64-apple-darwin" && prev.hostPlatform.system == x86_64-darwin
          then rustupToolchain'
          else
            rustupToolchain'
            // {
              targets = rustupToolchainTargets ++ [target];
            };

        rustToolchainFor = target: let
          rustupToolchain = rustupToolchainWithTarget target;
        in
          withToolchain final rustupToolchain;

        # buildPackageFor builds for `target`.
        # `extraArgs` are passed through to `buildPackage` verbatim.
        # NOTE: Upstream only provides binary caches for a subset of supported systems.
        buildPackageFor = target: extraArgs: let
          kebab2snake = replaceStrings ["-"] ["_"];
          rustToolchain = rustToolchainFor target;
          craneLib = mkCraneLib final rustToolchain;
          pkgsCross = pkgsFor final target;
          commonCrossArgs =
            {
              CARGO_BUILD_TARGET = target;
            }
            // optionalAttrs (final.stdenv.hostPlatform.config != target && target != wasm32-wasi) {
              stdenv = pkgsCross.stdenv;

              depsBuildBuild = [
                pkgsCross.stdenv.cc
              ];

              HOST_CC = "${final.stdenv.cc.targetPrefix}cc";

              "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "${pkgsCross.stdenv.cc.targetPrefix}cc";
            }
            // optionalAttrs (target == wasm32-wasi) {
              depsBuildBuild = [
                final.wasmtime
              ];

              CARGO_TARGET_WASM32_WASI_RUNNER = "wasmtime --disable-cache";
            };

          targetBuildOverrides = buildOverrides (commonOverrideArgs
            // commonCrossArgs
            // {
              inherit pkgsCross;
            });
        in
          buildPackage craneLib (commonCrossArgs
            // {
              cargoArtifacts = buildDeps craneLib (commonCrossArgs // extraArgs // targetBuildOverrides);
            }
            // extraArgs
            // targetBuildOverrides);

        buildCrossPackage.aarch64-apple-darwin = extraArgs:
          buildPackageFor "aarch64-apple-darwin" ({
              CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            }
            // extraArgs);

        buildCrossPackage.aarch64-unknown-linux-musl = extraArgs:
          buildPackageFor "aarch64-unknown-linux-musl" ({
              CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            }
            // extraArgs);

        buildCrossPackage.wasm32-wasi = buildPackageFor wasm32-wasi;

        buildCrossPackage.x86_64-apple-darwin = extraArgs:
          buildPackageFor "x86_64-apple-darwin" ({
              CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            }
            // extraArgs);

        buildCrossPackage.x86_64-unknown-linux-musl = extraArgs:
          buildPackageFor "x86_64-unknown-linux-musl" ({
              CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
            }
            // extraArgs);

        aarch64LinuxMuslBin = buildCrossPackage.aarch64-unknown-linux-musl commonReleaseArgs;
        aarch64LinuxMuslDebugBin = buildCrossPackage.aarch64-unknown-linux-musl commonDebugArgs;

        aarch64DarwinBin = buildCrossPackage.aarch64-apple-darwin commonReleaseArgs;
        aarch64DarwinDebugBin = buildCrossPackage.aarch64-apple-darwin commonDebugArgs;

        wasm32WasiBin = buildCrossPackage.wasm32-wasi commonReleaseArgs;
        wasm32WasiDebugBin = buildCrossPackage.wasm32-wasi commonDebugArgs;

        x86_64LinuxMuslBin = buildCrossPackage.x86_64-unknown-linux-musl commonReleaseArgs;
        x86_64LinuxMuslDebugBin = buildCrossPackage.x86_64-unknown-linux-musl commonDebugArgs;

        x86_64DarwinBin = buildCrossPackage.x86_64-apple-darwin commonReleaseArgs;
        x86_64DarwinDebugBin = buildCrossPackage.x86_64-apple-darwin commonDebugArgs;

        targets' = let
          default.aarch64-apple-darwin = prev.hostPlatform.isDarwin;
          default.aarch64-unknown-linux-musl = !prev.hostPlatform.isDarwin;
          default.wasm32-wasi = true;
          default.x86_64-apple-darwin = prev.hostPlatform.system == x86_64-darwin;
          default.x86_64-unknown-linux-musl = !prev.hostPlatform.isDarwin;

          all =
            default
            // optionalAttrs (targets != null) targets;
        in
          mapAttrs' (target: enabled:
            warnIf (enabled && !(default ? ${target})) ''
              target `${target}` is not supported
              set `targets.${target} = false` to remove this warning'' (nameValuePair target enabled))
          all;

        targetBins =
          optionalAttrs targets'.aarch64-unknown-linux-musl {
            "${pname'}-aarch64-unknown-linux-musl" = aarch64LinuxMuslBin;
            "${pname'}-debug-aarch64-unknown-linux-musl" = aarch64LinuxMuslDebugBin;
          }
          // optionalAttrs targets'.aarch64-apple-darwin {
            "${pname'}-aarch64-apple-darwin" = aarch64DarwinBin;
            "${pname'}-debug-aarch64-apple-darwin" = aarch64DarwinDebugBin;
          }
          // optionalAttrs targets'.wasm32-wasi {
            "${pname'}-wasm32-wasi" = wasm32WasiBin;
            "${pname'}-debug-wasm32-wasi" = wasm32WasiDebugBin;
          }
          // optionalAttrs targets'.x86_64-apple-darwin {
            "${pname'}-x86_64-apple-darwin" = x86_64DarwinBin;
            "${pname'}-debug-x86_64-apple-darwin" = x86_64DarwinDebugBin;
          }
          // optionalAttrs targets'.x86_64-unknown-linux-musl {
            "${pname'}-x86_64-unknown-linux-musl" = x86_64LinuxMuslBin;
            "${pname'}-debug-x86_64-unknown-linux-musl" = x86_64LinuxMuslDebugBin;
          };

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
          commonArgs
          commonOverrideArgs
          hostBuildOverrides
          hostCargoArtifacts
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
