{self, ...} @ inputs:
with self.lib; {
  mkFlake = import ./mkFlake.nix inputs;
  mkOverlay = import ./mkOverlay.nix inputs;

  defaultClippyConfig.allFeatures = true;
  defaultClippyConfig.allow = [];
  defaultClippyConfig.allTargets = true;
  defaultClippyConfig.deny = ["warnings"];
  defaultClippyConfig.features = [];
  defaultClippyConfig.forbid = [];
  defaultClippyConfig.noDefaultFeatures = false;
  defaultClippyConfig.targets = [];
  defaultClippyConfig.warn = [];
  defaultClippyConfig.workspace = true;

  defaultTestConfig.allFeatures = true;
  defaultTestConfig.allTargets = true;
  defaultTestConfig.features = [];
  defaultTestConfig.noDefaultFeatures = false;
  defaultTestConfig.targets = [];
  defaultTestConfig.workspace = true;

  defaultIgnorePaths =
    defaultIgnorePaths
    ++ [
      "/deny.toml"
      "/rust-toolchain.toml"
    ];
}
