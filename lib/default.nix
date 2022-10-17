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
      powerpc64le-linux
      x86_64-darwin
      x86_64-linux
    ];

    defaultWithChecks = {checks, ...}: checks;
    defaultWithDevShells = {devShells, ...}: devShells;
    defaultWithFormatter = {formatter, ...}: formatter;
    defaultWithOverlays = {overlays, ...}: overlays;
    defaultWithPackages = {packages, ...}: packages;
  };
in
  fix f
