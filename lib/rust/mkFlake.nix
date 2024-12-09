{
  self,
  crane,
  fenix,
  flake-utils,
  nixlib,
  rust-overlay,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
with builtins;
with self.lib;
with self.lib.rust;
{
  audit ? defaultAuditConfig,
  build ? defaultBuildConfig,
  buildOverrides ? defaultBuildOverrides,
  cargoLock ? null,
  clippy ? defaultClippyConfig,
  doc ? defaultDocConfig,
  doCheck ? true,
  excludePaths ? defaultExcludePaths,
  includePaths ? null,
  name ? null,
  nixpkgsConfig ? defaultNixpkgsConfig,
  overlays ? [ ],
  pkgsFor ? defaultPkgsFor,
  rustupToolchain ? null,
  src,
  systems ? defaultSystems,
  targets ? null,
  test ? defaultTestConfig,
  withApps ? defaultWithApps,
  withChecks ? defaultWithChecks,
  withDevShells ? defaultWithDevShells,
  withFormatter ? defaultWithFormatter,
  withOverlays ? defaultWithOverlays,
  withPackages ? defaultWithPackages,
  withToolchain ? defaultWithToolchain,
}:
let
  cargoToml = readTOML "${src}/Cargo.toml";
  pname = if name != null then name else pnameFromCargoToml cargoToml;
  version =
    if cargoToml.package.version.workspace or false then
      cargoToml.package.workspace.version or defaultVersion
    else
      cargoToml.package.version or defaultVersion;

  rustupToolchain' =
    if rustupToolchain == null then
      readTOMLOr "${src}/rust-toolchain.toml" defaultRustupToolchain
    else
      rustupToolchain;

  src' = filterSource {
    inherit src;
    exclude = excludePaths;
    include = includePaths;
  };

  # partially-applied `mkAttrs`
  mkAttrs' = mkAttrs {
    inherit
      build
      buildOverrides
      cargoLock
      clippy
      doc
      doCheck
      pkgsFor
      pname
      targets
      test
      version
      withToolchain
      ;
    src = src';
    rustupToolchain = rustupToolchain';
  };
in
self.lib.mkFlake {
  inherit
    excludePaths
    includePaths
    nixpkgsConfig
    pname
    systems
    version
    withFormatter
    ;
  src = src';

  overlays = overlays ++ [
    rust-overlay.overlays.default
    fenix.overlays.default
  ];

  withApps =
    {
      apps,
      packages,
      pkgs,
      ...
    }@cx:
    withApps (
      cx
      // {
        apps =
          apps
          # TODO: Add cross apps
          // optionalAttrs (packages ? "${pname}") {
            ${pname} = flake-utils.lib.mkApp {
              drv = packages."${pname}";
            };
          }
          // optionalAttrs (packages ? "${pname}-debug") {
            "${pname}-debug" = flake-utils.lib.mkApp {
              drv = packages."${pname}-debug";
            };
          };
      }
    );

  withChecks =
    {
      checks,
      pkgs,
      ...
    }@cx:
    let
      attrs = mkAttrs' pkgs;
    in
    withChecks (
      cx
      // {
        checks = checks // attrs.checks;
      }
    );

  withDevShells =
    {
      checks,
      devShells,
      packages,
      pkgs,
      ...
    }@cx:
    let
      attrs = mkAttrs' pkgs;
    in
    withDevShells (
      cx
      // {
        devShells = extendDerivations (
          {
            packages = [
              attrs.hostRustToolchain
            ];
          }
          // optionalAttrs (checks ? ${pname}) {
            inherit (checks.${pname})
              buildInputs
              depsBuildBuild
              nativeBuildInputs
              ;
          }
        ) devShells;
      }
    );

  withOverlays =
    { overlays, ... }@cx:
    withOverlays (
      cx
      // {
        overlays =
          let
            overlay = final: prev: (mkAttrs' final).overlay prev;
          in
          overlays
          // {
            ${pname} = overlay;
            default = overlay;
            fenix = fenix.overlays.default;
            rust-overlay = rust-overlay.overlays.default;
          };
      }
    );

  withPackages =
    {
      packages,
      pkgs,
      ...
    }@cx:
    let
      attrs = mkAttrs' pkgs;
      attrPkgs = optionalAttrs (attrs ? packages) attrs.packages;
    in
    withPackages (
      cx
      // {
        inherit (attrs)
          hostRustToolchain
          ;

        buildLib = attrs.lib;
        packages =
          packages
          // attrPkgs
          // optionalAttrs (attrPkgs ? ${pname}) {
            default = attrPkgs.${pname};
          };
      }
    );
}
