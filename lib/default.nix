{
  flake-utils,
  nixlib,
  nixpkgs,
  ...
} @ inputs:
with nixlib.lib;
with flake-utils.lib.system; let
  f = self': {
    rust = import ./rust inputs;

    mkFlake = import ./mkFlake.nix inputs self';

    extendDerivations = import ./extendDerivations.nix inputs;

    ignoreSourcePaths = {
      paths ? defaultIgnorePaths,
      src,
    }: let
      paths' = genAttrs paths (_: {});
      removeStorePrefix = x:
        if isStorePath x
        then "/" + concatStringsSep "/" (drop 1 (splitString "/" (removePrefix storeDir (strings.normalizePath x))))
        else strings.normalizePath x;
    in
      cleanSourceWith {
        inherit src;
        filter = name: type:
          !(paths' ? ${removeStorePrefix name});
      };

    defaultIgnorePaths = [
      "/.codecov.yml"
      "/.github"
      "/.gitignore"
      "/.mailmap"
      "/flake.lock"
      "/flake.nix"
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
