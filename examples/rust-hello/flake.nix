{
  inputs.nixify.url = github:rvolosatovs/nixify;

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
