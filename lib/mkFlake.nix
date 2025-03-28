{
  self,
  flake-utils,
  nixlib,
  nixpkgs-darwin,
  nixpkgs-nixos,
  ...
}:
{
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
with flake-utils.lib.system;
with nixlib.lib;
with builtins;
with self.lib;
{
  excludePaths ? defaultExcludePaths,
  includePaths ? null,
  nixpkgsConfig ? defaultNixpkgsConfig,
  overlays ? [ ],
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
}:
let
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
  overlays = withOverlays (
    commonArgs
    // {
      overlays = { };
    }
  );
}
// flake-utils.lib.eachSystem systems (
  system:
  let
    pkgs =
      import
        (if system == aarch64-darwin || system == x86_64-darwin then nixpkgs-darwin else nixpkgs-nixos)
        {
          inherit
            overlays
            system
            ;
          config = nixpkgsConfig;
        };

    commonPkgsArgs = commonArgs // {
      inherit
        pkgs
        ;
    };

    checks = withChecks (
      commonPkgsArgs
      // {
        checks = { };
      }
    );

    formatter = withFormatter (
      commonPkgsArgs
      // {
        formatter = pkgs.nixfmt-rfc-style;
      }
    );

    packages = withPackages (
      commonPkgsArgs
      // {
        packages = { };
      }
    );
  in
  {
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
