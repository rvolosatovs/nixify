{
  inputs.nixify.url = github:rvolosatovs/nixify;

  description = "Rust hello world";

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;
      ignorePaths = [
        "/.gitignore"
        "/flake.lock"
        "/flake.nix"
        "/rust-toolchain.toml"
      ];
    };
}
