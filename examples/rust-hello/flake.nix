{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs =
    { self, nixify, ... }:
    nixify.lib.rust.mkFlake {
      src = self;

      nixpkgsConfig.allowUnfree = true;

      # these match the defaults; passing `excludePaths` replaces (not extends) them
      excludePaths = [
        ".gitignore"
        "flake.lock"
        "flake.nix"
        "rust-toolchain.toml"
      ];

      targets =
        pkgs:
        {
          aarch64-apple-darwin = true;
          aarch64-unknown-linux-gnu = true;
          aarch64-unknown-linux-musl = true;
          arm-unknown-linux-gnueabihf = true;
          arm-unknown-linux-musleabihf = true;
          armv7-unknown-linux-gnueabihf = true;
          armv7-unknown-linux-musleabihf = true;
          powerpc64le-unknown-linux-gnu = true;
          riscv64gc-unknown-linux-gnu = true;
          s390x-unknown-linux-gnu = true;
          wasm32-unknown-unknown = true;
          wasm32-wasip2 = true;
          x86_64-apple-darwin = true;
          x86_64-pc-windows-gnu = true;
          x86_64-unknown-linux-gnu = true;
          x86_64-unknown-linux-musl = true;
        }
        # Android NDK only builds on x86_64-linux.
        //
          pkgs.lib.optionalAttrs (pkgs.stdenv.buildPlatform.isLinux && pkgs.stdenv.buildPlatform.isx86_64)
            {
              aarch64-linux-android = true;
            };
    };
}
