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

      targets.aarch64-apple-darwin = true;
      targets.aarch64-linux-android = true;
      targets.aarch64-unknown-linux-gnu = true;
      targets.aarch64-unknown-linux-musl = true;
      targets.arm-unknown-linux-gnueabihf = true;
      targets.arm-unknown-linux-musleabihf = true;
      targets.armv7-unknown-linux-gnueabihf = true;
      targets.armv7-unknown-linux-musleabihf = true;
      targets.powerpc64le-unknown-linux-gnu = true;
      targets.riscv64gc-unknown-linux-gnu = true;
      targets.s390x-unknown-linux-gnu = true;
      targets.wasm32-unknown-unknown = true;
      targets.wasm32-wasip2 = true;
      targets.x86_64-apple-darwin = true;
      targets.x86_64-pc-windows-gnu = true;
      targets.x86_64-unknown-linux-gnu = true;
      targets.x86_64-unknown-linux-musl = true;
    };
}
