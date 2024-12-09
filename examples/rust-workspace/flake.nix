{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs =
    { nixify, ... }:
    nixify.lib.rust.mkFlake {
      src = ./.;
      name = "rust-workspace";

      build.workspace = true;
      clippy.workspace = true;
      test.workspace = true;
    };
}
