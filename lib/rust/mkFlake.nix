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
    ignorePaths ? defaultIgnorePaths,
    clippy ? defaultClippyConfig,
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

    mkOverlay' = cx:
      mkOverlay (cx
        // {
          rustupToolchainFile = "${src}/rust-toolchain.toml";
        });
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

      withChecks = {
        checks,
        pkgs,
        ...
      } @ cx: let
        checks' = checks // pkgs."${pname}Checks";
      in
        withChecks (cx
          // {
            checks = checks';
          });

      withDevShells = {
        devShells,
        pkgs,
        ...
      } @ cx: let
        default = devShells.default.overrideAttrs (attrs: {
          buildInputs =
            attrs.buildInputs
            ++ [
              pkgs."${pname}RustToolchain"
            ];
        });
      in
        withDevShells (cx
          // {
            devShells =
              devShells
              // {
                inherit
                  default
                  ;
              };
          });

      withOverlays = {overlays, ...} @ cx: let
        default = mkOverlay' (filterAttrs (n: v: n != "overlays") cx);
      in
        withOverlays (cx
          // {
            overlays =
              overlays
              // {
                inherit
                  default
                  ;
              };
          });

      withPackages = {
        packages,
        pkgs,
        ...
      } @ cx: let
        system = pkgs.hostPlatform.system;

        packages' =
          packages
          // {
            default = pkgs.${pname};
          }
          // genAttrs ([
              "${pname}"
              "${pname}-aarch64-unknown-linux-musl"
              "${pname}-aarch64-unknown-linux-musl-oci"
              "${pname}-wasm32-wasi"
              "${pname}-wasm32-wasi-oci"
              "${pname}-x86_64-unknown-linux-musl"
              "${pname}-x86_64-unknown-linux-musl-oci"

              "${pname}-debug"
              "${pname}-debug-aarch64-unknown-linux-musl"
              "${pname}-debug-aarch64-unknown-linux-musl-oci"
              "${pname}-debug-wasm32-wasi"
              "${pname}-debug-wasm32-wasi-oci"
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
      in
        withPackages (cx
          // {
            packages = packages';
          });

      withPkgs = {
        system,
        overlays,
        ...
      } @ cx: let
        overlay = mkOverlay' (filterAttrs (n: v: n != "overlays" && n != "system") cx);
      in
        import nixpkgs {
          inherit system;
          overlays =
            [
              # NOTE: Order is important
              rust-overlay.overlays.default
              overlay
            ]
            ++ mapAttrsToList (n: overlay: overlay) overlays;
        };
    }
