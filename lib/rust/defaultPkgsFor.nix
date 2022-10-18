# constructs a package set for specified `target` given `pkgs`.
{
  flake-utils,
  nixpkgs,
  ...
}:
with flake-utils.lib.system; let
in
  pkgs: target: let
    withCrossSystem = crossSystem:
      import nixpkgs {
        inherit crossSystem;
        localSystem = pkgs.hostPlatform.system;
      };
  in
    if pkgs.hostPlatform.system == target
    then pkgs
    else if target == wasm32-wasi
    then pkgs
    else if pkgs.hostPlatform.system == aarch64-darwin && target == "aarch64-apple-darwin"
    then pkgs
    else if pkgs.hostPlatform.system == aarch64-linux && target == "aarch64-unknown-linux-gnu"
    then pkgs
    else if pkgs.hostPlatform.system == aarch64-linux && target == "aarch64-unknown-linux-musl"
    then pkgs
    else if pkgs.hostPlatform.system == x86_64-darwin && target == "x86_64-apple-darwin"
    then pkgs
    else if pkgs.hostPlatform.system == x86_64-linux && target == "x86_64-unknown-linux-gnu"
    then pkgs
    else if pkgs.hostPlatform.system == x86_64-linux && target == "x86_64-unknown-linux-musl"
    then pkgs
    else if target == "aarch64-unknown-linux-musl"
    then withCrossSystem aarch64-linux
    else if target == "aarch64-apple-darwin"
    then pkgs.pkgsCross.aarch64-darwin
    else if target == "x86_64-unknown-linux-musl"
    then withCrossSystem x86_64-linux
    else if target == "x86_64-apple-darwin"
    then pkgs.pkgsCross.x86_64-darwin
    else withCrossSystem target
