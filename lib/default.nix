{
  flake-utils,
  nixlib,
  nixpkgs,
  nix-filter,
  ...
} @ inputs:
with flake-utils.lib.system;
with nixlib.lib;
with builtins; let
  f = self': {
    eq = x: y: x == y;

    rust = import ./rust inputs;

    mkFlake = import ./mkFlake.nix inputs self';

    extendDerivations = import ./extendDerivations.nix inputs;

    filterSource = {
      include ? null,
      exclude ? self'.defaultExcludePaths,
      src,
    }:
      nix-filter.lib.filter ({
          inherit exclude;
          root = src;
        }
        // optionalAttrs (include != null) {
          inherit include;
        });

    readTOML = file: fromTOML (readFile file);
    readTOMLOr = path: def:
      if pathExists path
      then self'.readTOML path
      else def;

    defaultExcludePaths = [
      ".codecov.yml"
      ".github"
      ".gitignore"
      ".mailmap"
      "flake.lock"
      "flake.nix"
    ];

    defaultSystems = [
      aarch64-darwin
      aarch64-linux
      x86_64-darwin
      x86_64-linux
    ];

    defaultWithApps = {apps, ...}: apps;
    defaultWithChecks = {checks, ...}: checks;
    defaultWithDevShells = {devShells, ...}: devShells;
    defaultWithFormatter = {formatter, ...}: formatter;
    defaultWithOverlays = {overlays, ...}: overlays;
    defaultWithPackages = {packages, ...}: packages;
  };
in
  fix f
