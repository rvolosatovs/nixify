{
  inputs.nixify.url = github:rvolosatovs/nixify;

  outputs = {
    nixify,
    ...
  }:
    nixify.lib.rust.mkFlake {
      # Rust project's source code
      src = ./.;

      ## Paths, which are not required by any cargo invocation
      #ignorePaths = [
      #  "/.codecov.yml"
      #  "/.github"
      #  "/.gitignore"
      #  "/.mailmap"
      #  "/deny.toml"
      #  "/flake.lock"
      #  "/flake.nix"
      #  "/rust-toolchain.toml"
      #];
      #
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
