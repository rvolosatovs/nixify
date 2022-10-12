{
  inputs.nixify.url = github:rvolosatovs/nixify;
  inputs.nixlib.url = github:nix-community/nixpkgs.lib;

  description = "Rust hello world";

  outputs = {
    nixify,
    nixlib,
    ...
  }:
    nixify.lib.rust.mkFlake {
      src = nixlib.lib.cleanSource ./.;
    };
}
