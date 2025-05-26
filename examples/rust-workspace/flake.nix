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
      name = "rust-workspace";

      nixpkgsConfig.allowUnfree = true;

      build.workspace = true;
      clippy.workspace = true;
      test.workspace = true;
    };
}
