{
  self,
  nixlib,
  ...
} @ inputs:
with self.lib;
with nixlib.lib; {
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;

  # extract package name from parsed Cargo.toml
  pnameFromCargoToml = cargoToml:
    cargoToml.package.name
    or (throw "`name` must either be specified in `Cargo.toml` `[package]` section or passed as an argument");

  # version used when not specified in Cargo.toml
  defaultVersion = "0.0.0-unspecified";

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

  defaultRustupToolchain.toolchain.channel = "stable";
  defaultRustupToolchain.toolchain.components = ["rustfmt" "clippy"];

  defaultTestConfig.allFeatures = false;
  defaultTestConfig.allTargets = false;
  defaultTestConfig.features = [];
  defaultTestConfig.noDefaultFeatures = false;
  defaultTestConfig.targets = [];
  defaultTestConfig.workspace = false;

  defaultBuildOverrides = const {};

  defaultExcludePaths =
    defaultExcludePaths
    ++ [
      "rust-toolchain.toml"
    ];
}
