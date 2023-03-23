# constructs a package set for specified `target` given `pkgs`.
{
  flake-utils,
  nixpkgs,
  ...
}:
with flake-utils.lib.system;
  pkgs: target:
    if pkgs.hostPlatform.config == target
    then pkgs
    else if pkgs.hostPlatform.system == armv7l-linux && target == "armv7-unknown-linux-musleabihf"
    then pkgs
    else if pkgs.hostPlatform.system == aarch64-linux && target == "aarch64-unknown-linux-musl"
    then pkgs
    else if pkgs.hostPlatform.system == x86_64-windows && target == "x86_64-pc-windows-gnu"
    then pkgs
    else if pkgs.hostPlatform.system == x86_64-linux && target == "x86_64-unknown-linux-musl"
    then pkgs
    else if target == "aarch64-unknown-linux-musl"
    then pkgs.pkgsCross.aarch64-multiplatform
    else if target == "aarch64-apple-darwin"
    then pkgs.pkgsCross.aarch64-darwin
    else if target == "armv7-unknown-linux-musleabihf"
    then pkgs.pkgsCross.armv7l-hf-multiplatform
    else if target == "x86_64-apple-darwin"
    then pkgs.pkgsCross.x86_64-darwin
    else if target == "x86_64-pc-windows-gnu"
    then pkgs.pkgsCross.mingwW64
    else if target == "x86_64-unknown-linux-musl"
    then pkgs.pkgsCross.gnu64
    else if target == wasm32-wasi
    then pkgs.pkgsCross.wasi32
    else
      import nixpkgs {
        crossSystem = target;
        localSystem = pkgs.hostPlatform.system;
      }
