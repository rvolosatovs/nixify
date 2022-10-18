{
  self,
  flake-utils,
  nixlib,
  nixpkgs,
  ...
} @ inputs:
with flake-utils.lib.system;
with self.lib;
with nixlib.lib; let
  f = self': {
    mkFlake = import ./mkFlake.nix inputs;
    mkOverlay = import ./mkOverlay.nix inputs;
    mkPkgsFor = import ./mkPkgsFor.nix inputs;

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

    defaultPkgsFor = self'.mkPkgsFor {};
    defaultTargets = [
      "aarch64-apple-darwin"
      "aarch64-unknown-linux-musl"
      "wasm32-wasi"
      "x86_64-apple-darwin"
      "x86_64-unknown-linux-musl"
    ];

    defaultIgnorePaths =
      defaultIgnorePaths
      ++ [
        "/deny.toml"
        "/rust-toolchain.toml"
      ];
  };
in
  fix f
