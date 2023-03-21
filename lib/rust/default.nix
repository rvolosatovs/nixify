{
  self,
  crane,
  nixlib,
  ...
} @ inputs:
with nixlib.lib;
with self.lib;
{
  mkAttrs = import ./mkAttrs.nix inputs;
  mkChecks = import ./mkChecks.nix inputs;
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;
  mkPackages = import ./mkPackages.nix inputs;

  # mkCraneLib constructs a crane library for specified `pkgs`.
  mkCraneLib = pkgs: rustToolchain: (crane.mkLib pkgs).overrideToolchain rustToolchain;

  # mkCargoFlags constructs a set of cargo flags from `config`
  mkCargoFlags = config:
    with config;
      concatStrings (
        optionals (config ? targets) (map (target: "--target ${target} ") config.targets)
        ++ optional (config ? features && length config.features > 0) "--features ${concatStringsSep "," config.features} "
        ++ optional (config ? allFeatures && config.allFeatures) "--all-features "
        ++ optional (config ? allTargets && config.allTargets) "--all-targets "
        ++ optional (config ? noDefaultFeatures && config.noDefaultFeatures) "--no-default-features "
        ++ optional (config ? workspace && config.workspace) "--workspace "
      );

  # commonDebugArgs is a set of common arguments to debug builds
  commonDebugArgs.CARGO_PROFILE = "dev";

  # commonReleaseArgs is a set of common arguments to release builds
  commonReleaseArgs = {};

  # crateBins returns a list of binaries that would be produced by cargo build
  crateBins = import ./crateBins.nix inputs;

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
