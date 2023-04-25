{
  inputs.nixify.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixify.url = github:rvolosatovs/nixify;
  inputs.nixpkgs.url = github:NixOS/nixpkgs;

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;

      excludePaths = [
        "rust-toolchain.toml"
      ];

      build.workspace = true;
      clippy.workspace = true;
      test.workspace = true;

      targets.wasm32-wasi = false; # https://github.com/briansmith/ring/issues/1043
    };
}
