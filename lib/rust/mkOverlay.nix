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
    build ? defaultBuildConfig,
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    pkgsFor ? defaultPkgsFor,
    pname,
    src,
    targets ? null,
    test ? defaultTestConfig,
    version,
    withToolchain ? defaultWithToolchain,
  }: final: prev: let
    eq = x: y: x == y;

    readTOML = file: fromTOML (readFile file);
    readTOMLOr = path: def:
      if pathExists path
      then readTOML path
      else def;

    defaultRustupToolchain.toolchain.channel = "stable";
    defaultRustupToolchain.toolchain.components = ["rustfmt" "clippy"];

    rustupToolchain = (readTOMLOr "${src}/rust-toolchain.toml" defaultRustupToolchain).toolchain;
    rustupToolchainTargets = rustupToolchain.targets or [];
    rustupToolchainWithTarget = target:
      if any (eq target) rustupToolchainTargets
      then rustupToolchain
      else if target == "aarch64-apple-darwin" && prev.hostPlatform.system == aarch64-darwin
      then rustupToolchain
      else if target == "x86_64-apple-darwin" && prev.hostPlatform.system == x86_64-darwin
      then rustupToolchain
      else
        rustupToolchain
        // {
          targets = rustupToolchainTargets ++ [target];
        };

    crateBins = src: let
      cargoToml = readTOML "${src}/Cargo.toml";

      isPackage = cargoToml ? package;

      autobins = isPackage && cargoToml.package.autobins or true;
      bin = optionals isPackage cargoToml.bin or [];
      workspace = cargoToml.workspace.members or [];

      unglob' = prefix: parts:
        if parts == []
        then [prefix]
        else let
          h = head parts;
          t = tail parts;
        in
          if hasInfix "*" h
          then let
            regex = "^${replaceStrings ["*"] [".*"] h}$";
            names = filter (name: match regex name != null) (attrNames (readDir prefix));
          in
            map (h': unglob' "${prefix}/${h'}" t) names
          else unglob' "${prefix}/${h}" t;

      unglob = glob: let
        prefix = optionalString (!(hasPrefix "/" glob)) src;
        parts = splitString "/" glob;
      in
        optionals (glob != "") (unglob' prefix parts);

      workspace' = unique (flatten (map unglob workspace));
    in
      (map ({name, ...}: name) bin)
      ++ optional (autobins && pathExists "${src}/src/main.rs") cargoToml.package.name
      ++ optionals (autobins && pathExists "${src}/src/bin") (map (removeSuffix ".rs") (attrNames (filterAttrs (name: type: type == "regular" && hasSuffix ".rs" name) (readDir "${src}/src/bin"))))
      ++ optionals (!isPackage || build.workspace) (flatten (map crateBins workspace'));

    bins = unique (crateBins src);
    isLib = length bins == 0;

    # mkCraneLib constructs a crane library for specified `pkgs`.
    mkCraneLib = pkgs: rustToolchain: (crane.mkLib pkgs).overrideToolchain rustToolchain;

    # hostRustToolchain is the default Rust toolchain.
    hostRustToolchain = withToolchain final rustupToolchain;

    # hostCraneLib is the crane library for the host native triple.
    hostCraneLib = mkCraneLib final hostRustToolchain;

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

    # commonArgs is a set of arguments that is common to all crane invocations.
    commonArgs = let
      buildArgs = "-j $NIX_BUILD_CORES ${mkCargoFlags build}";
      checkArgs = "-j $NIX_BUILD_CORES";
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
        pname
        src
        version
        ;

      cargoBuildCommand = "cargoWithProfile build ${buildArgs}";
      cargoCheckCommand = "cargoWithProfile check ${checkArgs}";
      cargoClippyExtraArgs = clippyArgs;
      cargoNextestExtraArgs = testArgs;
      cargoTestExtraArgs = testArgs;

      installCargoArtifactsMode = "use-zstd";
    };

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
        // {
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
        // extraArgs
        // hostBuildOverrides
      );

    # hostCargoArtifacts are the cargo artifacts built for the host native triple.
    hostCargoArtifacts = buildDeps hostCraneLib {};

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
    checks.fmt = hostCraneLib.cargoFmt (commonArgs // hostBuildOverrides);
    checks.nextest = hostCraneLib.cargoNextest (
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

    # buildPackage builds using `craneLib`.
    # `extraArgs` are passed through to `craneLib.buildPackage` verbatim.
    buildPackage = craneLib: extraArgs:
      craneLib.buildPackage (commonArgs
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
        // extraArgs);

    buildHostPackage = extraArgs:
      buildPackage hostCraneLib (
        {
          cargoArtifacts = hostCargoArtifacts;
        }
        // extraArgs
        // hostBuildOverrides
      );

    # buildPackageFor builds for `target`.
    # `extraArgs` are passed through to `buildPackage` verbatim.
    # NOTE: Upstream only provides binary caches for a subset of supported systems.
    buildPackageFor = target: extraArgs: let
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

      rustupToolchain = rustupToolchainWithTarget target;
      rustToolchain = withToolchain final rustupToolchain;
      craneLib = mkCraneLib pkgsCross rustToolchain;

      targetBuildOverrides = buildOverrides (commonOverrideArgs
        // commonCrossArgs
        // {
          inherit pkgsCross;
        });
    in
      buildPackage craneLib (commonCrossArgs
        // {
          cargoArtifacts = buildDeps craneLib (commonCrossArgs // targetBuildOverrides);
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

    commonReleaseArgs = {};
    commonDebugArgs = {
      CARGO_PROFILE = "";
    };

    hostBin = buildHostPackage commonReleaseArgs;
    hostDebugBin = buildHostPackage commonDebugArgs;

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

    buildImage = bin:
      final.dockerTools.buildImage {
        name = pname;
        tag = version;
        copyToRoot = final.buildEnv {
          name = pname;
          paths = [bin];
        };
        config.Cmd = [pname];
        config.Env = ["PATH=${bin}/bin"];
      };

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
        "${pname}-aarch64-unknown-linux-musl" = aarch64LinuxMuslBin;
        "${pname}-debug-aarch64-unknown-linux-musl" = aarch64LinuxMuslDebugBin;
      }
      // optionalAttrs targets'.aarch64-apple-darwin {
        "${pname}-aarch64-apple-darwin" = aarch64DarwinBin;
        "${pname}-debug-aarch64-apple-darwin" = aarch64DarwinDebugBin;
      }
      // optionalAttrs targets'.wasm32-wasi {
        "${pname}-wasm32-wasi" = wasm32WasiBin;
        "${pname}-debug-wasm32-wasi" = wasm32WasiDebugBin;
      }
      // optionalAttrs targets'.x86_64-apple-darwin {
        "${pname}-x86_64-apple-darwin" = x86_64DarwinBin;
        "${pname}-debug-x86_64-apple-darwin" = x86_64DarwinDebugBin;
      }
      // optionalAttrs targets'.x86_64-unknown-linux-musl {
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
      "${pname}RustToolchain" = hostRustToolchain;
    }
    // optionalAttrs (!isLib) packages
