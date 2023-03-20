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
with self.lib;
with self.lib.rust;
  {
    build ? defaultBuildConfig,
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    excludePaths ? defaultExcludePaths,
    includePaths ? null,
    name ? null,
    overlays ? [],
    pkgsFor ? defaultPkgsFor,
    src,
    systems ? defaultSystems,
    targets ? null,
    test ? defaultTestConfig,
    withApps ? defaultWithApps,
    withChecks ? defaultWithChecks,
    withDevShells ? defaultWithDevShells,
    withFormatter ? defaultWithFormatter,
    withOverlays ? defaultWithOverlays,
    withPackages ? defaultWithPackages,
    withToolchain ? defaultWithToolchain,
  }: let
    cargoToml = readTOML "${src}/Cargo.toml";
    pname =
      if name != null
      then name
      else pnameFromCargoToml cargoToml;
    version = cargoToml.package.version or defaultVersion;

    rustupToolchain = (readTOMLOr "${src}/rust-toolchain.toml" defaultRustupToolchain).toolchain;

    src' = filterSource {
      inherit src;
      exclude = excludePaths;
      include = includePaths;
    };

    overlay = mkOverlay {
      inherit
        build
        buildOverrides
        cargoLock
        clippy
        pkgsFor
        pname
        rustupToolchain
        targets
        test
        version
        withToolchain
        ;
      src = src';
    };
  in
    self.lib.mkFlake {
      inherit
        excludePaths
        includePaths
        pname
        systems
        version
        withFormatter
        ;
      src = src';

      overlays =
        overlays
        ++ [
          rust-overlay.overlays.default
          overlay
        ];

      withApps = {
        apps,
        packages,
        pkgs,
        ...
      } @ cx:
        withApps (cx
          // {
            apps =
              apps
              # TODO: Add cross apps
              // optionalAttrs (packages ? "${pname}") {
                ${pname} = flake-utils.lib.mkApp {
                  drv = packages."${pname}";
                };
              }
              // optionalAttrs (packages ? "${pname}-debug") {
                "${pname}-debug" = flake-utils.lib.mkApp {
                  drv = packages."${pname}-debug";
                };
              };
          });

      withChecks = {
        checks,
        pkgs,
        ...
      } @ cx:
        withChecks (cx
          // {
            checks = checks // pkgs."${pname}Checks";
          });

      withDevShells = {
        devShells,
        pkgs,
        ...
      } @ cx:
        withDevShells (cx
          // {
            devShells =
              extendDerivations {
                buildInputs = [
                  pkgs."${pname}RustToolchain"
                ];
              }
              devShells;
          });

      withOverlays = {overlays, ...} @ cx:
        withOverlays (cx
          // {
            overlays =
              overlays
              // {
                ${pname} = overlay;
                default = overlay;
                rust = rust-overlay.overlays.default;
              };
          });

      withPackages = {
        packages,
        pkgs,
        ...
      } @ cx:
        withPackages (cx
          // {
            buildLib = pkgs."${pname}Lib";
            hostRustToolchain = pkgs."${pname}RustToolchain";

            packages = let
              overlayPkgs = getAttrs (filter (name: pkgs ? ${name})
                [
                  "${pname}"
                  "${pname}-aarch64-apple-darwin"
                  "${pname}-aarch64-apple-darwin-oci"
                  "${pname}-aarch64-unknown-linux-musl"
                  "${pname}-aarch64-unknown-linux-musl-oci"
                  "${pname}-wasm32-wasi"
                  "${pname}-wasm32-wasi-oci"
                  "${pname}-x86_64-apple-darwin"
                  "${pname}-x86_64-apple-darwin-oci"
                  "${pname}-x86_64-unknown-linux-musl"
                  "${pname}-x86_64-unknown-linux-musl-oci"

                  "${pname}-debug"
                  "${pname}-debug-aarch64-apple-darwin"
                  "${pname}-debug-aarch64-apple-darwin-oci"
                  "${pname}-debug-aarch64-unknown-linux-musl"
                  "${pname}-debug-aarch64-unknown-linux-musl-oci"
                  "${pname}-debug-wasm32-wasi"
                  "${pname}-debug-wasm32-wasi-oci"
                  "${pname}-debug-x86_64-apple-darwin"
                  "${pname}-debug-x86_64-apple-darwin-oci"
                  "${pname}-debug-x86_64-unknown-linux-musl"
                  "${pname}-debug-x86_64-unknown-linux-musl-oci"
                ])
              pkgs;
            in
              packages
              // overlayPkgs
              // optionalAttrs (overlayPkgs ? "${pname}") {
                default = overlayPkgs."${pname}";
              };
          });
    }
