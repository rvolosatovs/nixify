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
  dummySrc ? null,
  excludePaths ? defaultExcludePaths,
  includePaths ? null,
  name ? null,
  nixpkgsConfig ? defaultNixpkgsConfig,
  overlays ? [ ],
  overrideVendorCargoPackage ? null,
  overrideVendorGitCheckout ? null,
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
      cargoToml.workspace.package.version or defaultVersion
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

  bins = crateBins {
    inherit build;
    src = src';
  };

  # partially-applied `mkAttrs`
  mkAttrs' = mkAttrs {
    inherit
      bins
      build
      buildOverrides
      cargoLock
      clippy
      doc
      doCheck
      overrideVendorCargoPackage
      overrideVendorGitCheckout
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
    let
      mkBinApps =
        suffix:
        optionalAttrs (packages ? "${pname}${suffix}") (
          listToAttrs (
            map (
              bin:
              nameValuePair "${bin}${suffix}" (
                flake-utils.lib.mkApp {
                  drv = packages."${pname}${suffix}";
                  exePath = "/bin/${bin}";
                }
              )
            ) bins
          )
        );

      mkDefaultBinApp =
        suffix:
        optionalAttrs (packages ? "${pname}${suffix}" && packages."${pname}${suffix}".passthru ? exePath) {
          "${pname}${suffix}" = flake-utils.lib.mkApp { drv = packages."${pname}${suffix}"; };
        };

      binApps = mkBinApps "-debug" // mkBinApps "" // mkDefaultBinApp "-debug" // mkDefaultBinApp "";

      apps' =
        if (packages.default.pname or null) == pname && !(packages.default.passthru ? exePath) then
          removeAttrs apps [ "default" ]
        else
          apps;
    in
    withApps (
      cx
      // {
        apps =
          apps'
          # TODO: Add cross apps
          // binApps;
      }
    );

  withChecks =
    { checks, pkgs, ... }@cx:
    let
      attrs = mkAttrs' pkgs;
    in
    withChecks (cx // { checks = checks // attrs.checks; });

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
        devShells = extendDerivations { nativeBuildInputs = [ attrs.hostRustToolchain ]; } devShells;
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
    { packages, pkgs, ... }@cx:
    let
      attrs = mkAttrs' pkgs;
      attrPkgs = optionalAttrs (attrs ? packages) attrs.packages;
    in
    withPackages (
      cx
      // {
        inherit (attrs)
          buildHostPackage
          buildImageDir
          buildImageManifest
          callCrane
          callCraneWithDeps
          callHostCrane
          callHostCraneCheckWithDeps
          callHostCraneWithDeps
          hostCraneLib
          hostRustToolchain
          ;

        packages =
          packages // attrPkgs // optionalAttrs (attrPkgs ? ${pname}) { default = attrPkgs.${pname}; };
      }
    );
}
