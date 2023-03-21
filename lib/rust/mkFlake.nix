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
with builtins;
with self.lib;
with self.lib.rust;
  {
    build ? defaultBuildConfig,
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    excludePaths ? defaultExcludePaths,
    includePaths ? null,
    name ? null,
    overlays ? [],
    pkgsFor ? defaultPkgsFor,
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
  }: let
    cargoToml = readTOML "${src}/Cargo.toml";
    pname =
      if name != null
      then name
      else pnameFromCargoToml cargoToml;
    version = cargoToml.package.version or defaultVersion;

    rustupToolchain = readTOMLOr "${src}/rust-toolchain.toml" defaultRustupToolchain;

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
        pkgsFor
        pname
        rustupToolchain
        targets
        test
        version
        withToolchain
        ;
      src = src';
    };

    overlay = let
      overlay' = final: let
        attrs = mkAttrs' final;
      in
        if attrs ? overlay
        then attrs.overlay
        else const {};
    in
      final: prev: overlay' final prev;
  in
    self.lib.mkFlake {
      inherit
        excludePaths
        includePaths
        pname
        systems
        version
        withFormatter
        ;
      src = src';

      overlays =
        overlays
        ++ [
          rust-overlay.overlays.default
          overlay
        ];

      withApps = {
        apps,
        packages,
        pkgs,
        ...
      } @ cx:
        withApps (cx
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
          });

      withChecks = {
        checks,
        pkgs,
        ...
      } @ cx: let
        attrs = mkAttrs' pkgs;
      in
        withChecks (cx
          // {
            checks = checks // attrs.checks;
          });

      withDevShells = {
        devShells,
        pkgs,
        ...
      } @ cx: let
        attrs = mkAttrs' pkgs;
      in
        withDevShells (cx
          // {
            devShells =
              extendDerivations {
                packages = [
                  attrs.hostRustToolchain
                ];
              }
              devShells;
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
        attrs = mkAttrs' pkgs;
        attrPkgs = optionalAttrs (attrs ? packages) attrs.packages;
      in
        withPackages (cx
          // {
            buildLib = attrs.lib;
            hostRustToolchain = attrs.toolchain;
            packages =
              packages
              // attrPkgs
              // optionalAttrs (attrPkgs ? ${pname}) {
                default = attrPkgs.${pname};
              };
          });
    }
