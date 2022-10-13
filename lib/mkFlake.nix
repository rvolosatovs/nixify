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
with self.lib;
  {
    ignorePaths ? defaultIgnorePaths,
    pname,
    src,
    systems ? defaultSystems,
    version,
    withChecks ? defaultWithChecks,
    withDevShells ? defaultWithDevShells,
    withFormatter ? defaultWithFormatter,
    withOverlays ? defaultWithOverlays,
    withPackages ? defaultWithPackages,
    withPkgs ? defaultWithPkgs,
  }: let
    ignorePaths' = genAttrs ignorePaths (_: {});
    src' = cleanSourceWith {
      inherit src;
      filter = name: type: !(ignorePaths' ? "${removePrefix "${src}" name}");
    };

    commonArgs = {
      inherit
        pname
        version
        ;

      src = src';
    };

    overlays = withOverlays (commonArgs
      // {
        overlays = {};
      });
  in
    {
      inherit overlays;
    }
    // flake-utils.lib.eachSystem systems
    (
      system: let
        pkgs = withPkgs (commonArgs
          // {
            inherit
              overlays
              system
              ;
          });

        commonPkgsArgs =
          commonArgs
          // {
            inherit
              pkgs
              ;
          };
      in {
        checks = withChecks (commonPkgsArgs
          // {
            checks = {};
          });

        devShells = withDevShells (commonPkgsArgs
          // {
            devShells.default = pkgs.mkShell {
              inherit
                pname
                version
                ;
            };
          });

        formatter = withFormatter (commonPkgsArgs
          // {
            formatter = pkgs.alejandra;
          });

        packages = withPackages (commonPkgsArgs
          // {
            packages = {};
          });
      }
    )
