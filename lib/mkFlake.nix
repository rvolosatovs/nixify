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

        checks = withChecks (commonPkgsArgs
          // {
            checks = {};
          });

        formatter = withFormatter (commonPkgsArgs
          // {
            formatter = pkgs.alejandra;
          });

        packages = withPackages (commonPkgsArgs
          // {
            packages = {};
          });
      in {
        inherit
          formatter
          checks
          packages
          ;

        apps = withApps (
          commonPkgsArgs
          // {
            inherit
              packages
              ;

            apps = optionalAttrs (packages ? default) {
              default = flake-utils.lib.mkApp {
                drv = packages.default;
              };
            };
          }
        );

        devShells = withDevShells (
          commonPkgsArgs
          // {
            inherit
              formatter
              checks
              packages
              ;

            devShells.default = pkgs.mkShell (
              {
                packages = [
                  formatter
                ];
              }
              // optionalAttrs (packages ? default) {
                inherit
                  (packages.default)
                  buildInputs
                  depsBuildBuild
                  nativeBuildInputs
                  ;
              }
              // optionalAttrs (pname != null) {
                inherit pname;
              }
              // optionalAttrs (version != null) {
                inherit version;
              }
            );
          }
        );
      }
    )
