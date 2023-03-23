{
  inputs.nixify.url = github:rvolosatovs/nixify;

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;

      excludePaths = [
        "rust-toolchain.toml"
      ];

      targets.wasm32-wasi = false; # https://github.com/briansmith/ring/issues/1043
    };
}
