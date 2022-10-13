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
      #withChecks = {
      #  checks,
      #  pkgs,
      #  pname,
      #  src,
      #  version,
      #  ...
      #}:
      #  checks;
      #
      ## Development shell output generation
      #withDevShells = {
      #  devShells,
      #  pkgs,
      #  pname,
      #  src,
      #  version,
      #  ...
      #}:
      #  devShells;
      #
      ## Formatter output generation
      #withFormatter = {
      #  formatter,
      #  pkgs,
      #  pname,
      #  src,
      #  version,
      #  ...
      #}:
      #  formatter;
      #
      ## Overlay output generation
      #withOverlays = {
      #  overlays,
      #  pname,
      #  src,
      #  version,
      #  ...
      #}:
      #  overlays;
      #
      ## Package output generation
      #withPackages = {
      #  packages,
      #  pkgs,
      #  pname,
      #  src,
      #  version,
      #  ...
      #}:
      #  packages;
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
