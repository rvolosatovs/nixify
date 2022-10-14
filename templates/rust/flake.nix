{
  inputs.nixify.url = github:rvolosatovs/nixify;

  outputs = {nixify, ...}:
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
      ## Overlays to use in nixpkgs instantiaion
      #overlays = [];
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
      #test.allFeatures = false;
      #test.allTargets = false;
      #test.noDefaultFeatures = false;
      #test.features = [];
      #test.targets = [];
      #test.workspace = false;

      ## Clippy configuration
      #clippy.allFeatures = false;
      #clippy.allTargets = false;
      #clippy.noDefaultFeatures = false;
      #clippy.features = [];
      #clippy.targets = [];
      #clippy.workspace = false;

      #clippy.allow = [];
      #clippy.deny = [];
      #clippy.forbid = [];
      #clippy.warn = [];
    };
}
