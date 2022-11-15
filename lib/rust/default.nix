{
  self,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
} @ inputs:
with self.lib;
with nixlib.lib; {
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;

  defaultPkgsFor = import ./defaultPkgsFor.nix inputs;
  defaultWithToolchain = pkgs: pkgs.rust-bin.fromRustupToolchain;

  defaultBuildConfig.allFeatures = false;
  defaultBuildConfig.allTargets = false;
  defaultBuildConfig.features = [];
  defaultBuildConfig.noDefaultFeatures = false;
  defaultBuildConfig.workspace = false;

  defaultClippyConfig.allFeatures = false;
  defaultClippyConfig.allow = [];
  defaultClippyConfig.allTargets = false;
  defaultClippyConfig.deny = [];
  defaultClippyConfig.features = [];
  defaultClippyConfig.forbid = [];
  defaultClippyConfig.noDefaultFeatures = false;
  defaultClippyConfig.targets = [];
  defaultClippyConfig.warn = [];
  defaultClippyConfig.workspace = false;

  defaultTestConfig.allFeatures = false;
  defaultTestConfig.allTargets = false;
  defaultTestConfig.features = [];
  defaultTestConfig.noDefaultFeatures = false;
  defaultTestConfig.targets = [];
  defaultTestConfig.workspace = false;

  defaultBuildOverrides = const {};

  defaultIgnorePaths =
    defaultIgnorePaths
    ++ [
      "/deny.toml"
      "/rust-toolchain.toml"
    ];
}
