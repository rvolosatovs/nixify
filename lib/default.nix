{
  flake-utils,
  nixpkgs,
  ...
} @ inputs:
with flake-utils.lib.system; {
  mkFlake = import ./mkFlake.nix inputs;

  rust = import ./rust inputs;

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
  defaultWithPkgs = {system, ...}:
    import nixpkgs {
      inherit system;
    };
}
