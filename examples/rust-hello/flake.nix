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

      nixpkgsConfig.allowUnfree = true;

      excludePaths = [
        ".gitignore"
        "flake.lock"
        "flake.nix"
        "rust-toolchain.toml"
      ];
    };
}
