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
  ...
}:
with nixlib.lib;
  {
    ignorePaths ? defaultIgnorePaths,
    overlays ? [],
    pname ? null,
    src ? null,
    systems ? defaultSystems,
    version ? null,
    withChecks ? defaultWithChecks,
    withDevShells ? defaultWithDevShells,
    withFormatter ? defaultWithFormatter,
    withOverlays ? defaultWithOverlays,
    withPackages ? defaultWithPackages,
  }: let
    commonArgs =
      optionalAttrs (pname != null) {
        inherit pname;
      }
      // optionalAttrs (version != null) {
        inherit version;
      }
      // optionalAttrs (src != null) {
        src = let
          ignorePaths' = genAttrs ignorePaths (_: {});
          removeSrc = removePrefix "${src}";
        in
          cleanSourceWith {
            inherit src;
            filter = name: type: !(ignorePaths' ? ${removeSrc name});
          };
      };
  in
    {
      overlays = withOverlays (commonArgs
        // {
          overlays = {};
        });
    }
    // flake-utils.lib.eachSystem systems
    (
      system: let
        pkgs = import nixpkgs {
          inherit
            overlays
            system
            ;
        };

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
            devShells.default = pkgs.mkShell (
              optionalAttrs (pname != null) {
                inherit pname;
              }
              // optionalAttrs (version != null) {
                inherit version;
              }
            );
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
