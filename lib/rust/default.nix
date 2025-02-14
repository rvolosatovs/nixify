{
  self,
  advisory-db,
  crane,
  nixlib,
  ...
}@inputs:
with nixlib.lib;
with builtins;
with self.lib;
let
  defaultRustupToolchain.toolchain.channel = "stable";
  defaultRustupToolchain.toolchain.components = [
    "rustfmt"
    "clippy"
  ];

  # crateBins returns a list of binaries that would be produced by cargo build
  crateBins = import ./crateBins.nix inputs;

  # mkCargoFlags constructs a set of cargo flags from `config`
  mkCargoFlags =
    config:
    with config;
    concatStrings (
      optionals (config ? targets) (map (target: "--target ${target} ") config.targets)
      ++ optionals (config ? packages) (map (package: "--package ${package} ") config.packages)
      ++ optionals (config ? excludes) (map (exclude: "--exclude ${exclude} ") config.excludes)
      ++ optionals (config ? bins) (map (bin: "--bin ${bin} ") config.bins)
      ++ optional (
        config ? features && length config.features > 0
      ) "--features ${concatStringsSep "," config.features} "
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
  pnameFromCargoToml =
    cargoToml:
    cargoToml.package.name
      or (throw "`name` must either be specified in `Cargo.toml` `[package]` section or passed as an argument");

  withRustOverlayToolchain = pkgs: pkgs.rust-bin.fromRustupToolchain;
  withFenixToolchain =
    pkgs:
    {
      channel ? defaultRustupToolchain.toolchain.channel,
      components ? defaultRustupToolchain.toolchain.components,
      targets ? [ ],
      ...
    }@args:
    with pkgs;
    let
      channels.stable = "stable";
      channels.beta = "beta";
      channels.nightly = "latest";

      channel' = channels.${channel};
      targets' = map (target: fenix.targets.${target}.${channel'}.rust-std) targets;
      toolchain = fenix.combine (
        [
          (fenix.${channel'}.withComponents (components ++ [ "cargo" ]))
        ]
        ++ targets'
      );
    in
    if channels ? ${channel} then
      toolchain
    else
      warn
        "only one of ${toJSON (attrNames channels)} `channel` specifications are supported for `fenix`, falling back to rust-overlay (which may break some cross-compilation scenarios)"
        withRustOverlayToolchain
        pkgs
        args;
in
{
  inherit
    crateBins
    defaultRustupToolchain
    mkAttrs
    mkCargoFlags
    mkChecks
    mkCraneLib
    mkFlake
    mkOverlay
    mkPackages
    pnameFromCargoToml
    withFenixToolchain
    withRustOverlayToolchain
    ;

  # commonDebugArgs is a set of common arguments to debug builds
  commonDebugArgs.CARGO_PROFILE = "dev";

  # commonReleaseArgs is a set of common arguments to release builds
  commonReleaseArgs = { };

  # version used when not specified in Cargo.toml
  defaultVersion = "0.0.0-unspecified";

  defaultPkgsFor = import ./defaultPkgsFor.nix inputs;
  defaultWithToolchain = withFenixToolchain;

  defaultAuditConfig.database = advisory-db;

  defaultBuildConfig.allFeatures = false;
  defaultBuildConfig.allTargets = false;
  defaultBuildConfig.bins = [ ];
  defaultBuildConfig.excludes = [ ];
  defaultBuildConfig.features = [ ];
  defaultBuildConfig.noDefaultFeatures = false;
  defaultBuildConfig.packages = [ ];
  defaultBuildConfig.workspace = false;

  defaultClippyConfig.allFeatures = false;
  defaultClippyConfig.allow = [ ];
  defaultClippyConfig.allTargets = false;
  defaultClippyConfig.deny = [ ];
  defaultClippyConfig.features = [ ];
  defaultClippyConfig.forbid = [ ];
  defaultClippyConfig.noDefaultFeatures = false;
  defaultClippyConfig.packages = [ ];
  defaultClippyConfig.targets = [ ];
  defaultClippyConfig.warn = [ ];
  defaultClippyConfig.workspace = false;

  defaultDocConfig.allFeatures = false;
  defaultDocConfig.allTargets = false;
  defaultDocConfig.excludes = [ ];
  defaultDocConfig.features = [ ];
  defaultDocConfig.noDefaultFeatures = false;
  defaultDocConfig.packages = [ ];
  defaultDocConfig.workspace = false;

  defaultTestConfig.allFeatures = false;
  defaultTestConfig.allTargets = false;
  defaultTestConfig.doc = false;
  defaultTestConfig.excludes = [ ];
  defaultTestConfig.features = [ ];
  defaultTestConfig.noDefaultFeatures = false;
  defaultTestConfig.packages = [ ];
  defaultTestConfig.targets = [ ];
  defaultTestConfig.workspace = false;

  defaultBuildOverrides = _: const { };

  defaultOverrideVendorCargoPackage = _: const { };
  defaultOverrideVendorGitCheckout = _: const { };

  defaultExcludePaths = defaultExcludePaths ++ [
    "rust-toolchain.toml"
  ];

  # From https://doc.rust-lang.org/nightly/rustc/platform-support.html
  targets.aarch64-apple-darwin = "aarch64-apple-darwin";
  targets.aarch64-apple-ios = "aarch64-apple-ios";
  targets.aarch64-linux-android = "aarch64-linux-android";
  targets.aarch64-unknown-linux-gnu = "aarch64-unknown-linux-gnu";
  targets.aarch64-unknown-linux-musl = "aarch64-unknown-linux-musl";
  targets.arm-unknown-linux-musleabi = "arm-unknown-linux-musleabi";
  targets.arm-unknown-linux-musleabihf = "arm-unknown-linux-musleabihf";
  targets.arm-unknown-linux-gnueabi = "arm-unknown-linux-gnueabi";
  targets.arm-unknown-linux-gnueabihf = "arm-unknown-linux-gnueabihf";
  targets.armv7-unknown-linux-gnueabi = "armv7-unknown-linux-gnueabi";
  targets.armv7-unknown-linux-gnueabihf = "armv7-unknown-linux-gnueabihf";
  targets.armv7-unknown-linux-musleabi = "armv7-unknown-linux-musleabi";
  targets.armv7-unknown-linux-musleabihf = "armv7-unknown-linux-musleabihf";
  targets.armv7s-apple-ios = "armv7s-apple-ios";
  targets.mips-unknown-linux-gnu = "mips-unknown-linux-gnu";
  targets.mips-unknown-linux-musl = "mips-unknown-linux-musl";
  targets.mips64-unknown-linux-gnuabi64 = "mips64-unknown-linux-gnuabi64";
  targets.mips64-unknown-linux-muslabi64 = "mips64-unknown-linux-muslabi64";
  targets.mips64el-unknown-linux-gnuabi64 = "mips64el-unknown-linux-gnuabi64";
  targets.mips64el-unknown-linux-muslabi64 = "mips64el-unknown-linux-muslabi64";
  targets.mipsel-unknown-linux-gnu = "mipsel-unknown-linux-gnu";
  targets.mipsel-unknown-linux-musl = "mipsel-unknown-linux-musl";
  targets.powerpc-unknown-linux-gnu = "powerpc-unknown-linux-gnu";
  targets.powerpc-unknown-linux-musl = "powerpc-unknown-linux-musl";
  targets.powerpc64-unknown-linux-gnu = "powerpc64-unknown-linux-gnu";
  targets.powerpc64-unknown-linux-musl = "powerpc64-unknown-linux-musl";
  targets.powerpc64le-unknown-linux-gnu = "powerpc64le-unknown-linux-gnu";
  targets.powerpc64le-unknown-linux-musl = "powerpc64le-unknown-linux-musl";
  targets.riscv64gc-unknown-linux-gnu = "riscv64gc-unknown-linux-gnu";
  targets.riscv64gc-unknown-linux-musl = "riscv64gc-unknown-linux-musl";
  targets.s390x-unknown-linux-gnu = "s390x-unknown-linux-gnu";
  targets.s390x-unknown-linux-musl = "s390x-unknown-linux-musl";
  targets.wasm32-unknown-unknown = "wasm32-unknown-unknown";
  targets.wasm32-wasip1 = "wasm32-wasip1";
  targets.wasm32-wasip2 = "wasm32-wasip2";
  targets.x86_64-apple-darwin = "x86_64-apple-darwin";
  targets.x86_64-apple-ios = "x86_64-apple-ios";
  targets.x86_64-pc-windows-gnu = "x86_64-pc-windows-gnu";
  targets.x86_64-unknown-linux-gnu = "x86_64-unknown-linux-gnu";
  targets.x86_64-unknown-linux-musl = "x86_64-unknown-linux-musl";
}
