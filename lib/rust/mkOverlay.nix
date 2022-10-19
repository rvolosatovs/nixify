{
  self,
  crane,
  flake-utils,
  nixlib,
  ...
}:
with builtins;
with flake-utils.lib.system;
with nixlib.lib;
with self.lib.rust;
  {
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    pkgsFor ? defaultPkgsFor,
    src,
    test ? defaultTestConfig,
    withToolchain ? defaultWithToolchain,
  }: final: prev: let
    cargoToml = fromTOML (readFile "${src}/Cargo.toml");
    pname = cargoToml.package.name;
    version = cargoToml.package.version;
    autobins =
      if cargoToml.package ? autobins
      then cargoToml.package.autobins
      else true;
    bins =
      unique
      (optional (cargoToml ? bin) (map ({name, ...}: name))
        ++ optional (autobins && pathExists "${src}/src/main.rs") pname
        ++ optionals (autobins && pathExists "${src}/src/bin") (map (removeSuffix ".rs") (attrNames (filterAttrs (name: type: type == "regular" && hasSuffix ".rs" name) (readDir "${src}/src/bin")))));
    isLib = length bins == 0;

    rustupToolchain = (fromTOML (readFile "${src}/rust-toolchain.toml")).toolchain;
    rustToolchain = withToolchain final rustupToolchain;

    # mkCraneLib constructs a crane library for specified `pkgs`.
    mkCraneLib = pkgs: (crane.mkLib pkgs).overrideToolchain rustToolchain;

    # hostCraneLib is the crane library for the host native triple.
    hostCraneLib = mkCraneLib final;

    # commonArgs is a set of arguments that is common to all crane invocations.
    commonArgs = {
      inherit
        pname
        src
        version
        ;
    };

    commonOverrideArgs =
      commonArgs
      // {
        pkgs = final;
      };

    hostBuildOverrides = buildOverrides commonOverrideArgs;

    mkCargoFlags = config:
      with config;
        concatStrings (
          optionals (config ? targets) (map (target: "--target ${target} ") config.targets)
          ++ optional (config ? features && length config.features > 0) "--features ${concatStringsSep "," config.features} "
          ++ optional (config ? allFeatures && config.allFeatures) "--all-features "
          ++ optional (config ? allTargets && config.allTargets) "--all-targets "
          ++ optional (config ? noDefaultFeatures && config.noDefaultFeatures) "--no-default-features "
          ++ optional (config ? workspace && config.workspace) "--workspace "
        );

    # buildDeps builds dependencies of the crate given `craneLib`.
    # `extraArgs` are passed through to `craneLib.buildDepsOnly` verbatim.
    buildDeps = craneLib: extraArgs:
      craneLib.buildDepsOnly (
        commonArgs
        // {
          cargoExtraArgs = "-j $NIX_BUILD_CORES";

          # Remove binary dependency specification, since that breaks on generated "dummy source"
          extraDummyScript = ''
            sed -i '/^artifact = "bin"$/d' $out/Cargo.toml
            sed -i '/^target = ".*"$/d' $out/Cargo.toml
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
        // optionalAttrs (test != null) {
          cargoTestExtraArgs = mkCargoFlags test;
        }
        // extraArgs
        // hostBuildOverrides
      );

    # hostCargoArtifacts are the cargo artifacts built for the host native triple.
    hostCargoArtifacts = buildDeps hostCraneLib {};

    checks.clippy = hostCraneLib.cargoClippy (
      commonArgs
      // {
        cargoArtifacts = hostCargoArtifacts;
        cargoExtraArgs = "-j $NIX_BUILD_CORES";
      }
      // optionalAttrs (cargoLock != null) {
        cargoVendorDir = hostCraneLib.vendorCargoDeps {
          inherit
            cargoLock
            src
            ;
        };
      }
      // optionalAttrs (clippy != null) {
        cargoClippyExtraArgs = "${mkCargoFlags clippy} -- ${
          with clippy;
            concatStrings (
              optionals (clippy ? allow) (map (lint: "--allow ${lint} ") allow)
              ++ optionals (clippy ? deny) (map (lint: "--deny ${lint} ") deny)
              ++ optionals (clippy ? forbid) (map (lint: "--forbid ${lint} ") forbid)
              ++ optionals (clippy ? warn) (map (lint: "--warn ${lint} ") warn)
            )
        }";
      }
      // hostBuildOverrides
    );
    checks.fmt = hostCraneLib.cargoFmt (commonArgs // hostBuildOverrides);
    checks.nextest = hostCraneLib.cargoNextest (
      commonArgs
      // {
        cargoArtifacts = hostCargoArtifacts;
        cargoExtraArgs = "-j $NIX_BUILD_CORES";
      }
      // optionalAttrs (cargoLock != null) {
        cargoVendorDir = hostCraneLib.vendorCargoDeps {
          inherit
            cargoLock
            src
            ;
        };
      }
      // optionalAttrs (test != null) {
        cargoNextestExtraArgs = mkCargoFlags test;
      }
      // hostBuildOverrides
    );

    # buildPackage builds using `craneLib`.
    # `extraArgs` are passed through to `craneLib.buildPackage` verbatim.
    build.package = craneLib: extraArgs:
      craneLib.buildPackage (commonArgs
        // {
          cargoExtraArgs = "-j $NIX_BUILD_CORES";
        }
        // optionalAttrs (!isLib) {
          installPhaseCommand = ''
            mkdir -p $out/bin
            profileDir=''${CARGO_PROFILE:-debug}
            ${concatMapStringsSep "\n" (name: ''
                case ''${CARGO_BUILD_TARGET} in
                    ${wasm32-wasi})
                        cp target/${wasm32-wasi}/''${profileDir}/${name}.wasm $out/bin/${name};;
                    "")
                        cp target/''${profileDir}/${name} $out/bin/${name};;
                    *)
                        cp target/''${CARGO_BUILD_TARGET}/''${profileDir}/${name} $out/bin/${name};;
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
        // optionalAttrs (test != null) {
          cargoTestExtraArgs = mkCargoFlags test;
        }
        // extraArgs);

    build.host.package = extraArgs:
      build.package hostCraneLib (
        {
          cargoArtifacts = hostCargoArtifacts;
        }
        // extraArgs
        // hostBuildOverrides
      );

    # build.packageFor builds for `target`.
    # `extraArgs` are passed through to `build.package` verbatim.
    # NOTE: Upstream only provides binary caches for a subset of supported systems.
    build.packageFor = target: extraArgs: let
      pkgsCross = pkgsFor final target;
      kebab2snake = replaceStrings ["-"] ["_"];
      commonCrossArgs = with pkgsCross;
        {
          depsBuildBuild =
            if target == wasm32-wasi
            then [
              final.wasmtime
            ]
            else [
              stdenv.cc
            ];

          CARGO_BUILD_TARGET = target;
        }
        // optionalAttrs (target == wasm32-wasi) {
          CARGO_TARGET_WASM32_WASI_RUNNER = "wasmtime --disable-cache";
        }
        // optionalAttrs (target != wasm32-wasi) {
          "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "${stdenv.cc.targetPrefix}cc";
        };
      craneLib = mkCraneLib pkgsCross;

      targetBuildOverrides = buildOverrides (commonOverrideArgs
        // commonCrossArgs
        // {
          inherit pkgsCross;
        });
    in
      build.package craneLib (commonCrossArgs
        // {
          cargoArtifacts = buildDeps craneLib (commonCrossArgs // targetBuildOverrides);
        }
        // extraArgs
        // targetBuildOverrides);

    build.aarch64-apple-darwin.package = extraArgs:
      build.packageFor "aarch64-apple-darwin" ({
          CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
        }
        // extraArgs);

    build.aarch64-unknown-linux-musl.package = extraArgs:
      build.packageFor "aarch64-unknown-linux-musl" ({
          CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
        }
        // extraArgs);

    build.wasm32-wasi.package = build.packageFor wasm32-wasi;

    build.x86_64-apple-darwin.package = extraArgs:
      build.packageFor "x86_64-apple-darwin" ({
          CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
        }
        // extraArgs);

    build.x86_64-unknown-linux-musl.package = extraArgs:
      build.packageFor "x86_64-unknown-linux-musl" ({
          CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
        }
        // extraArgs);

    commonReleaseArgs = {};
    commonDebugArgs = {
      CARGO_PROFILE = "";
    };

    hostBin = build.host.package commonReleaseArgs;
    hostDebugBin = build.host.package commonDebugArgs;

    aarch64LinuxMuslBin = build.aarch64-unknown-linux-musl.package commonReleaseArgs;
    aarch64LinuxMuslDebugBin = build.aarch64-unknown-linux-musl.package commonDebugArgs;

    aarch64DarwinBin = build.aarch64-apple-darwin.package commonReleaseArgs;
    aarch64DarwinDebugBin = build.aarch64-apple-darwin.package commonDebugArgs;

    wasm32WasiBin = build.wasm32-wasi.package commonReleaseArgs;
    wasm32WasiDebugBin = build.wasm32-wasi.package commonDebugArgs;

    x86_64LinuxMuslBin = build.x86_64-unknown-linux-musl.package commonReleaseArgs;
    x86_64LinuxMuslDebugBin = build.x86_64-unknown-linux-musl.package commonDebugArgs;

    x86_64DarwinBin = build.x86_64-apple-darwin.package commonReleaseArgs;
    x86_64DarwinDebugBin = build.x86_64-apple-darwin.package commonDebugArgs;

    buildImage = bin:
      final.dockerTools.buildImage {
        name = pname;
        tag = version;
        contents = [bin];
        config.Cmd = [pname];
        config.Env = ["PATH=${bin}/bin"];
      };

    targets' = genAttrs rustupToolchain.targets (_: {});
    targetBins =
      optionalAttrs (targets' ? "aarch64-unknown-linux-musl" && !prev.hostPlatform.isDarwin) {
        "${pname}-aarch64-unknown-linux-musl" = aarch64LinuxMuslBin;
        "${pname}-debug-aarch64-unknown-linux-musl" = aarch64LinuxMuslDebugBin;
      }
      // optionalAttrs (targets' ? "aarch64-apple-darwin" && prev.hostPlatform.isDarwin || prev.hostPlatform.system == aarch64-darwin) {
        "${pname}-aarch64-apple-darwin" = aarch64DarwinBin;
        "${pname}-debug-aarch64-apple-darwin" = aarch64DarwinDebugBin;
      }
      // optionalAttrs (targets' ? "wasm32-wasi") {
        "${pname}-wasm32-wasi" = wasm32WasiBin;
        "${pname}-debug-wasm32-wasi" = wasm32WasiDebugBin;
      }
      // optionalAttrs (prev.hostPlatform.system == x86_64-darwin) {
        "${pname}-x86_64-apple-darwin" = x86_64DarwinBin;
        "${pname}-debug-x86_64-apple-darwin" = x86_64DarwinDebugBin;
      }
      // optionalAttrs (targets' ? "x86_64-unknown-linux-musl" && !prev.hostPlatform.isDarwin) {
        "${pname}-x86_64-unknown-linux-musl" = x86_64LinuxMuslBin;
        "${pname}-debug-x86_64-unknown-linux-musl" = x86_64LinuxMuslDebugBin;
      };

    bins' = genAttrs bins (_: {});
    targetImages = optionalAttrs (bins' ? ${pname}) (mapAttrs' (target: bin: nameValuePair "${target}-oci" (buildImage bin)) targetBins);

    packages =
      {
        "${pname}" = hostBin;
        "${pname}-debug" = hostDebugBin;
      }
      // targetBins
      // targetImages;
  in
    {
      "${pname}Checks" = checks // optionalAttrs isLib packages;
      "${pname}RustToolchain" = rustToolchain;
    }
    // optionalAttrs (!isLib) packages
    // optionalAttrs (!isLib) {
      default = packages.${pname};
    }
