{
  inputs.nixify.url = github:rvolosatovs/nixify;
  inputs.nixlib.url = github:nix-community/nixpkgs.lib;

  outputs = {
    nixify,
    nixlib,
    ...
  }:
    nixify.lib.rust.mkFlake {
      # Rust project's source code
      src = nixlib.lib.cleanSource ./.;

      ## Systems to generate outputs for
      #systems = [
      #  "aarch64-darwin"
      #  "aarch64-linux"
      #  "powerpc64le-linux"
      #  "x86_64-darwin"
      #  "x86_64-linux"
      #];
      #
      ## Check output generation
      #withChecks = {checks, pkgs, ...}: checks;
      #
      ## Development shell output generation
      #withDevShells = {devShells, pkgs, ...}: devShells;
      #
      ## Formatter output generation
      #withFormatter = {formatter, pkgs, ...}: formatter;
      #
      ## Package output generation
      #withPackages = {packages, pkgs, ...}: packages;
      #
      ## Test configuration
      #test = {
      #  allFeatures = true;
      #  allTargets = true;
      #  noDefaultFeatures = false;
      #  features = [];
      #  targets = [];
      #  workspace = true;
      #};
      #
      ## Clippy configuration
      #clippy = {
      #  allFeatures = true;
      #  allTargets = true;
      #  noDefaultFeatures = false;
      #  features = [];
      #  targets = [];
      #  workspace = true;
      #
      #  allow = [];
      #  deny = ["warnings"];
      #  forbid = [];
      #  warn = [];
      #};
    };
}
