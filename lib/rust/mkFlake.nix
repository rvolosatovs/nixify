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
    targets = let
      toml = builtins.fromTOML (builtins.readFile rustupToolchainFile);
    in
      optionals (toml ? toolchain && toml.toolchain ? targets) toml.toolchain.targets;

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
              devShells
              // {
                default = devShells.default.overrideAttrs (attrs: {
                  buildInputs =
                    attrs.buildInputs
                    ++ [
                      pkgs."${pname}RustToolchain"
                    ];
                });
              };
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
      } @ cx: let
        rustPackages = mkPackages {
          inherit
            clippy
            pkgs
            pname
            rustupToolchainFile
            src
            targets
            test
            version
            ;
        };
      in
        withPackages (cx
          // {
            packages =
              packages
              // rustPackages
              // {
                default = rustPackages.${pname};
              };
          });
    }
