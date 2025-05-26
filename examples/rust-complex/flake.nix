{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs =
    {
      self,
      nixify,
      ...
    }:
    nixify.lib.rust.mkFlake {
      src = self;

      excludePaths = [
        "rust-toolchain.toml"
      ];

      nixpkgsConfig.allowUnfree = true;

      build.workspace = true;
      clippy.workspace = true;
      test.allTargets = true;
      test.workspace = true;
    };
}
