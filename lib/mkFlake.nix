{
  self,
  crane,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
}: {
  defaultExcludePaths,
  defaultSystems,
  defaultWithApps,
  defaultWithChecks,
  defaultWithDevShells,
  defaultWithFormatter,
  defaultWithOverlays,
  defaultWithPackages,
  ...
}:
with nixlib.lib;
with builtins;
  {
    excludePaths ? defaultExcludePaths,
    includePaths ? null,
    overlays ? [],
    pname ? null,
    src ? null,
    systems ? defaultSystems,
    version ? null,
    withApps ? defaultWithApps,
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
        src = filterSource {
          inherit src;
          exclude = excludePaths;
          include = includePaths;
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

        packages = withPackages (commonPkgsArgs
          // {
            packages = {};
          });
      in {
        inherit packages;

        apps = withApps (commonPkgsArgs
          // {
            inherit packages;

            apps = optionalAttrs (packages ? default) {
              default = flake-utils.lib.mkApp {
                drv = packages.default;
              };
            };
          });

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
      }
    )
