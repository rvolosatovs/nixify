{self, ...} @ inputs:
with self.lib; {
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;

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
}
