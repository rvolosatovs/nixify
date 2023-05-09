{
  self,
  crane,
  nixlib,
  ...
} @ inputs:
with nixlib.lib;
with builtins;
with self.lib; let
  defaultRustupToolchain.toolchain.channel = "stable";
  defaultRustupToolchain.toolchain.components = ["rustfmt" "clippy"];

  # crateBins returns a list of binaries that would be produced by cargo build
  crateBins = import ./crateBins.nix inputs;

  # mkCargoFlags constructs a set of cargo flags from `config`
  mkCargoFlags = config:
    with config;
      concatStrings (
        optionals (config ? targets) (map (target: "--target ${target} ") config.targets)
        ++ optionals (config ? packages) (map (package: "--package ${package} ") config.packages)
        ++ optional (config ? features && length config.features > 0) "--features ${concatStringsSep "," config.features} "
        ++ optional (config ? allFeatures && config.allFeatures) "--all-features "
        ++ optional (config ? allTargets && config.allTargets) "--all-targets "
        ++ optional (config ? noDefaultFeatures && config.noDefaultFeatures) "--no-default-features "
        ++ optional (config ? workspace && config.workspace) "--workspace "
      );

  # mkCraneLib constructs a crane library for specified `pkgs`.
  mkCraneLib = pkgs: rustToolchain: (crane.mkLib pkgs).overrideToolchain rustToolchain;

  mkAttrs = import ./mkAttrs.nix inputs;
  mkChecks = import ./mkChecks.nix inputs;
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;
  mkPackages = import ./mkPackages.nix inputs;

  # extract package name from parsed Cargo.toml
  pnameFromCargoToml = cargoToml:
    cargoToml.package.name
    or (throw "`name` must either be specified in `Cargo.toml` `[package]` section or passed as an argument");

  # version used when not specified in Cargo.toml
  defaultVersion = "0.0.0-unspecified";

  versionFromCargoToml = {
    cargoToml,
    workspace ? {},
  }:
    if cargoToml.package.version.workspace or false
    then cargoToml.workspace.package.version or workspace.package.version or defaultVersion
    else cargoToml.package.version or defaultVersion;

  withRustOverlayToolchain = pkgs: pkgs.rust-bin.fromRustupToolchain;
  withFenixToolchain = pkgs: {
    channel ? defaultRustupToolchain.toolchain.channel,
    components ? defaultRustupToolchain.toolchain.components,
    targets ? [],
  } @ args:
    with pkgs; let
      channels.stable = "stable";
      channels.beta = "beta";
      channels.nightly = "latest";

      channel' = channels.${channel};
      targets' = map (target: fenix.targets.${target}.${channel'}.rust-std) targets;
      toolchain = fenix.combine (
        [
          (fenix.${channel'}.withComponents (components ++ ["cargo"]))
        ]
        ++ targets'
      );
    in
      if channels ? ${channel}
      then toolchain
      else warn "only one of ${toJSON (attrNames channels)} `channel` specifications are supported for `fenix`, falling back to rust-overlay (which may break some cross-compilation scenarios)" withRustOverlayToolchain args;
in {
  inherit
    crateBins
    defaultRustupToolchain
    defaultVersion
    mkAttrs
    mkCargoFlags
    mkChecks
    mkCraneLib
    mkFlake
    mkOverlay
    mkPackages
    pnameFromCargoToml
    versionFromCargoToml
    withFenixToolchain
    withRustOverlayToolchain
    ;

  # commonDebugArgs is a set of common arguments to debug builds
  commonDebugArgs.CARGO_PROFILE = "dev";

  # commonReleaseArgs is a set of common arguments to release builds
  commonReleaseArgs = {};

  defaultPkgsFor = import ./defaultPkgsFor.nix inputs;
  defaultWithToolchain = withFenixToolchain;

  defaultBuildConfig.allFeatures = false;
  defaultBuildConfig.allTargets = false;
  defaultBuildConfig.features = [];
  defaultBuildConfig.noDefaultFeatures = false;
  defaultBuildConfig.packages = [];
  defaultBuildConfig.workspace = false;

  defaultClippyConfig.allFeatures = false;
  defaultClippyConfig.allow = [];
  defaultClippyConfig.allTargets = false;
  defaultClippyConfig.deny = [];
  defaultClippyConfig.features = [];
  defaultClippyConfig.forbid = [];
  defaultClippyConfig.noDefaultFeatures = false;
  defaultClippyConfig.packages = [];
  defaultClippyConfig.targets = [];
  defaultClippyConfig.warn = [];
  defaultClippyConfig.workspace = false;

  defaultDocConfig.allFeatures = false;
  defaultDocConfig.allTargets = false;
  defaultDocConfig.features = [];
  defaultDocConfig.noDefaultFeatures = false;
  defaultDocConfig.packages = [];
  defaultDocConfig.workspace = false;

  defaultTestConfig.allFeatures = false;
  defaultTestConfig.allTargets = false;
  defaultTestConfig.features = [];
  defaultTestConfig.noDefaultFeatures = false;
  defaultTestConfig.packages = [];
  defaultTestConfig.targets = [];
  defaultTestConfig.workspace = false;

  defaultBuildOverrides = _: const {};

  defaultExcludePaths =
    defaultExcludePaths
    ++ [
      "rust-toolchain.toml"
    ];

  targets.aarch64-apple-darwin = "aarch64-apple-darwin";
  targets.aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu";
  targets.aarch64-unknown-linux-musl = "aarch64-unknown-linux-musl";
  targets.armv7-unknown-linux-musleabihf = "armv7-unknown-linux-musleabihf";
  targets.wasm32-wasi = "wasm32-wasi";
  targets.x86_64-apple-darwin = "x86_64-apple-darwin";
  targets.x86_64-pc-windows-gnu = "x86_64-pc-windows-gnu";
  targets.x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu";
  targets.x86_64-unknown-linux-musl = "x86_64-unknown-linux-musl";
}
