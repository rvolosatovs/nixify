{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;

      excludePaths = [
        "rust-toolchain.toml"
      ];

      build.workspace = true;
      clippy.workspace = true;
      test.allTargets = true;
      test.workspace = true;
    };
}
