{
  self,
  crane,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
}:
with nixlib.lib;
  {
    systems,
    mkPkgs ? system:
      import nixpkgs {
        inherit system;
      },
    pname,
    version,
    withChecks ? {checks, ...}: checks,
    withDevShells ? {devShells, ...}: devShells,
    withFormatter ? {formatter, ...}: formatter,
    withOverlays ? {overlays, ...}: overlays,
    withPackages ? {packages, ...}: packages,
  }:
    {
      overlays = withOverlays {
        inherit
          pname
          version
          ;
        overlays = {};
      };
    }
    // flake-utils.lib.eachSystem systems
    (
      system: let
        pkgs = mkPkgs system;

        commonArgs = {
          inherit
            pkgs
            pname
            system
            version
            ;
        };

        checks = withChecks (commonArgs
          // {
            checks = {};
          });
        devShells = withDevShells (commonArgs
          // {
            devShells.default = pkgs.mkShell {
              inherit
                pname
                version
                ;
            };
          });
        formatter = withFormatter (commonArgs
          // {
            formatter = pkgs.alejandra;
          });
        packages = withPackages (commonArgs
          // {
            packages = {};
          });
      in {
        inherit
          checks
          devShells
          formatter
          packages
          ;
      }
    )
