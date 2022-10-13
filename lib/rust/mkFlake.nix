{
  self,
  crane,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
  {
    src,
    systems ? [
      aarch64-darwin
      aarch64-linux
      powerpc64le-linux
      x86_64-darwin
      x86_64-linux
    ],
    withChecks ? {checks, ...}: checks,
    withDevShells ? {devShells, ...}: devShells,
    withFormatter ? {formatter, ...}: formatter,
    withOverlays ? {overlays, ...}: overlays,
    withPackages ? {packages, ...}: packages,
    test ? {
      allFeatures = true;
      allTargets = true;
      noDefaultFeatures = false;
      features = [];
      targets = [];
      workspace = true;
    },
    clippy ? {
      allFeatures = true;
      allTargets = true;
      noDefaultFeatures = false;
      features = [];
      targets = [];
      workspace = true;

      allow = [];
      deny = ["warnings"];
      forbid = [];
      warn = [];
    },
  }: let
    cargoPackage = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package;
    pname = cargoPackage.name;
    version = cargoPackage.version;

    mkRustToolchain = pkgs: pkgs.rust-bin.fromRustupToolchainFile "${src}/rust-toolchain.toml";

    mkCargoFlags = config:
      with config;
        concatStrings (
          optionals (config ? targets) (map (target: "--target ${target} ") targets)
          ++ optional (config ? features && length features > 0) "--features ${concatStringsSep "," features} "
          ++ optional (config ? allFeatures && allFeatures) "--all-features "
          ++ optional (config ? allTargets && allTargets) "--all-targets "
          ++ optional (config ? noDefaultFeatures && noDefaultFeatures) "--no-default-features "
          ++ optional (config ? workspace && workspace) "--workspace "
        );

    overlay = final: prev: let
      rustToolchain = mkRustToolchain final;

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

      # buildDeps builds dependencies of the crate given `craneLib`.
      # `extraArgs` are passed through to `craneLib.buildDepsOnly` verbatim.
      buildDeps = craneLib: extraArgs:
        craneLib.buildDepsOnly (commonArgs
          // {
            cargoExtraArgs = "-j $NIX_BUILD_CORES";

            # Remove binary dependency specification, since that breaks on generated "dummy source"
            extraDummyScript = ''
              sed -i '/^artifact = "bin"$/d' $out/Cargo.toml
              sed -i '/^target = ".*"$/d' $out/Cargo.toml
            '';
          }
          // optionalAttrs (test != null) {
            cargoTestExtraArgs = mkCargoFlags test;
          }
          // extraArgs);

      # hostCargoArtifacts are the cargo artifacts built for the host native triple.
      hostCargoArtifacts = buildDeps hostCraneLib {};

      checks.clippy = hostCraneLib.cargoClippy (commonArgs
        // {
          cargoArtifacts = hostCargoArtifacts;
          cargoExtraArgs = "-j $NIX_BUILD_CORES";
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
        });
      checks.fmt = hostCraneLib.cargoFmt commonArgs;
      checks.nextest = hostCraneLib.cargoNextest (commonArgs
        // {
          cargoArtifacts = hostCargoArtifacts;
          cargoExtraArgs = "-j $NIX_BUILD_CORES";
        }
        // optionalAttrs (test != null) {
          cargoNextestExtraArgs = mkCargoFlags test;
        });

      # buildPackage builds using `craneLib`.
      # `extraArgs` are passed through to `craneLib.buildPackage` verbatim.
      build.package = craneLib: extraArgs: let
      in
        craneLib.buildPackage (commonArgs
          // {
            cargoExtraArgs = "-j $NIX_BUILD_CORES";

            installPhaseCommand = ''
              mkdir -p $out/bin
              cp target/''${CARGO_BUILD_TARGET:+''${CARGO_BUILD_TARGET}/}''${CARGO_PROFILE:-debug}/${pname} $out/bin/${pname}
            '';
          }
          // optionalAttrs (test != null) {
            cargoTestExtraArgs = mkCargoFlags test;
          }
          // extraArgs);

      build.host.package = extraArgs:
        build.package hostCraneLib (
          {
            buildInputs =
              optional final.stdenv.isDarwin
              final.darwin.apple_sdk.frameworks.Security;

            cargoArtifacts = hostCargoArtifacts;
            cargoExtraArgs = "-j $NIX_BUILD_CORES";
          }
          // extraArgs
        );

      # pkgsFor constructs a package set for specified `crossSystem`.
      pkgsFor = crossSystem: let
        localSystem = final.hostPlatform.system;
      in
        if localSystem == crossSystem
        then final
        else if crossSystem == x86_64-darwin
        then throw "cross compilation to x86_64-darwin not supported due to https://github.com/NixOS/nixpkgs/issues/180771"
        else
          import nixpkgs {
            inherit
              crossSystem
              localSystem
              ;
          };

      # build.packageFor builds for `target` using `crossSystem` toolchain.
      # `extraArgs` are passed through to `build.package` verbatim.
      # NOTE: Upstream only provides binary caches for a subset of supported systems.
      build.packageFor = crossSystem: target: extraArgs: let
        pkgs = pkgsFor crossSystem;
        cc = pkgs.stdenv.cc;
        kebab2snake = replaceStrings ["-"] ["_"];
        commonCrossArgs = {
          depsBuildBuild = [
            cc
          ];

          buildInputs =
            optional pkgs.stdenv.isDarwin
            pkgs.darwin.apple_sdk.frameworks.Security;

          CARGO_BUILD_TARGET = target;
          "CARGO_TARGET_${toUpper (kebab2snake target)}_LINKER" = "${cc.targetPrefix}cc";
        };
        craneLib = mkCraneLib pkgs;
      in
        build.package craneLib (commonCrossArgs
          // {
            cargoArtifacts = buildDeps craneLib commonCrossArgs;
          }
          // extraArgs);

      build.aarch64-apple-darwin.package = extraArgs:
        build.packageFor aarch64-darwin "aarch64-apple-darwin" ({
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
          }
          // extraArgs);

      build.aarch64-unknown-linux-musl.package = extraArgs:
        build.packageFor aarch64-linux "aarch64-unknown-linux-musl" ({
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
          }
          // extraArgs);

      build.wasm32-wasi.package = extraArgs:
      # TODO: Consider using wasm32-wasi cross package set.
        build.host.package ({
            nativeBuildInputs = [final.wasmtime];

            CARGO_WASM32_WASI_RUNNER = "wasmtime";
          }
          // extraArgs);

      build.x86_64-apple-darwin.package = extraArgs:
        build.packageFor x86_64-darwin "x86_64-apple-darwin" ({
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
          }
          // extraArgs);

      build.x86_64-unknown-linux-musl.package = extraArgs:
        build.packageFor x86_64-linux "x86_64-unknown-linux-musl" ({
            CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
          }
          // extraArgs);

      commonReleaseArgs = {};
      commonDebugArgs = {
        CARGO_PROFILE = "";
      };

      # hostBin is the binary built for host native triple.
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
    in {
      "${pname}" = hostBin;
      "${pname}-aarch64-apple-darwin" = aarch64DarwinBin;
      "${pname}-aarch64-apple-darwin-oci" = buildImage aarch64DarwinBin;
      "${pname}-aarch64-unknown-linux-musl" = aarch64LinuxMuslBin;
      "${pname}-aarch64-unknown-linux-musl-oci" = buildImage aarch64LinuxMuslBin;
      "${pname}-wasm32-wasi" = wasm32WasiBin;
      "${pname}-x86_64-apple-darwin" = x86_64DarwinBin;
      "${pname}-x86_64-apple-darwin-oci" = buildImage x86_64DarwinBin;
      "${pname}-x86_64-unknown-linux-musl" = x86_64LinuxMuslBin;
      "${pname}-x86_64-unknown-linux-musl-oci" = buildImage x86_64LinuxMuslBin;

      "${pname}-debug" = hostDebugBin;
      "${pname}-debug-aarch64-apple-darwin" = aarch64DarwinDebugBin;
      "${pname}-debug-aarch64-apple-darwin-oci" = buildImage aarch64DarwinDebugBin;
      "${pname}-debug-aarch64-unknown-linux-musl" = aarch64LinuxMuslDebugBin;
      "${pname}-debug-aarch64-unknown-linux-musl-oci" = buildImage aarch64LinuxMuslDebugBin;
      "${pname}-debug-wasm32-wasi" = wasm32WasiDebugBin;
      "${pname}-debug-x86_64-apple-darwin" = x86_64DarwinDebugBin;
      "${pname}-debug-x86_64-apple-darwin-oci" = buildImage x86_64DarwinDebugBin;
      "${pname}-debug-x86_64-unknown-linux-musl" = x86_64LinuxMuslDebugBin;
      "${pname}-debug-x86_64-unknown-linux-musl-oci" = buildImage x86_64LinuxMuslDebugBin;

      "${pname}Checks" = checks;
      "${pname}RustToolchain" = rustToolchain;
    };
  in
    self.lib.mkFlake {
      inherit
        pname
        systems
        version
        withFormatter
        ;

      mkPkgs = system:
        import nixpkgs {
          inherit system;
          overlays = [
            # NOTE: Order is important
            rust-overlay.overlays.default
            overlay
          ];
        };

      withChecks = {
        checks,
        pkgs,
        ...
      } @ cx:
        withChecks (cx
          // {
            checks = cx.checks // pkgs."${pname}Checks";
          });

      withDevShells = {
        devShells,
        pkgs,
        ...
      } @ cx:
        withDevShells (cx
          // {
            devShells.default = devShells.default.overrideAttrs (attrs: {
              buildInputs =
                attrs.buildInputs
                ++ [
                  pkgs."${pname}RustToolchain"
                ];
            });
          });

      withOverlays = {overlays, ...} @ cx:
        withOverlays (cx
          // {
            overlays =
              cx.overlays
              // {
                default = overlay;
              };
          });

      withPackages = {
        packages,
        pkgs,
        system,
        ...
      } @ cx:
        withPackages (cx
          // {
            packages =
              cx.packages
              // {
                default = pkgs."${pname}";
              }
              // genAttrs ([
                  "${pname}"
                  "${pname}-aarch64-unknown-linux-musl"
                  "${pname}-aarch64-unknown-linux-musl-oci"
                  "${pname}-wasm32-wasi"
                  "${pname}-x86_64-unknown-linux-musl"
                  "${pname}-x86_64-unknown-linux-musl-oci"

                  "${pname}-debug"
                  "${pname}-debug-aarch64-unknown-linux-musl"
                  "${pname}-debug-aarch64-unknown-linux-musl-oci"
                  "${pname}-debug-wasm32-wasi"
                  "${pname}-debug-x86_64-unknown-linux-musl"
                  "${pname}-debug-x86_64-unknown-linux-musl-oci"
                ]
                ++ optionals (system == aarch64-darwin || system == x86_64-darwin) [
                  "${pname}-aarch64-apple-darwin"
                  "${pname}-aarch64-apple-darwin-oci"

                  "${pname}-debug-aarch64-apple-darwin"
                  "${pname}-debug-aarch64-apple-darwin-oci"
                ]
                ++ optionals (system == x86_64-darwin) [
                  # cross compilation to x86_64-darwin not supported due to https://github.com/NixOS/nixpkgs/issues/180771
                  "${pname}-x86_64-apple-darwin"
                  "${pname}-x86_64-apple-darwin-oci"

                  "${pname}-debug-x86_64-apple-darwin"
                  "${pname}-debug-x86_64-apple-darwin-oci"
                ]) (name: pkgs.${name});
          });
    }
