{
  self,
  crane,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
}: {
  defaultIgnorePaths,
  defaultSystems,
  defaultWithChecks,
  defaultWithDevShells,
  defaultWithFormatter,
  defaultWithOverlays,
  defaultWithPackages,
  defaultWithPkgs,
  ...
}:
with nixlib.lib;
  {
    ignorePaths ? defaultIgnorePaths,
    pname,
    src ? null,
    systems ? defaultSystems,
    version ? null,
    withChecks ? defaultWithChecks,
    withDevShells ? defaultWithDevShells,
    withFormatter ? defaultWithFormatter,
    withOverlays ? defaultWithOverlays,
    withPackages ? defaultWithPackages,
    withPkgs ? defaultWithPkgs,
  }: let
    commonArgs =
      {
        inherit
          pname
          version
          ;
      }
      // (optionalAttrs (src != null) {
        src = let
          ignorePaths' = genAttrs ignorePaths (_: {});
          removeSrc = removePrefix "${src}";
        in
          cleanSourceWith {
            inherit src;
            filter = name: type: !(ignorePaths' ? ${removeSrc name});
          };
      });

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
