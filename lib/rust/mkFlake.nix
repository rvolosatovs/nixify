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
    src,
    clippy ? defaultClippyConfig,
    ignorePaths ? defaultIgnorePaths,
    overlays ? [],
    systems ? defaultSystems,
    test ? defaultTestConfig,
    withChecks ? defaultWithChecks,
    withDevShells ? defaultWithDevShells,
    withFormatter ? defaultWithFormatter,
    withOverlays ? defaultWithOverlays,
    withPackages ? defaultWithPackages,
  }: let
    cargoPackage = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package;
    pname = cargoPackage.name;
    version = cargoPackage.version;

    rustupToolchainFile = "${src}/rust-toolchain.toml";
    targets = attrByPath ["toolchain" "targets"] [] (builtins.fromTOML (builtins.readFile rustupToolchainFile));

    overlay = mkOverlay {
      inherit
        clippy
        pname
        rustupToolchainFile
        src
        targets
        test
        version
        ;
    };
  in
    self.lib.mkFlake {
      inherit
        ignorePaths
        pname
        src
        systems
        version
        withFormatter
        ;

      overlays =
        overlays
        ++ [
          rust-overlay.overlays.default
          overlay
        ];

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
            packages =
              packages
              // {
                default = pkgs.${pname};

                ${pname} = pkgs.${pname};
                "${pname}-debug" = pkgs."${pname}-debug";
              }
              // getAttrs (filter (name: pkgs ? ${name})
                [
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
          });
    }
