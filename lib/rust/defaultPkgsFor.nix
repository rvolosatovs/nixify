# constructs a package set for specified `target` given `pkgs`.
{
  self,
  flake-utils,
  nixpkgs,
  ...
}:
with flake-utils.lib.system;
with self.lib.rust.targets;
  pkgs: target: let
    hostPlatform = pkgs.stdenv.hostPlatform;
  in
    if hostPlatform.config == target
    then pkgs
    else if hostPlatform.isAarch32 && hostPlatform.isLinux && hostPlatform.isMusl && target == armv7-unknown-linux-musleabihf
    then pkgs
    else if hostPlatform.isAarch64 && hostPlatform.isLinux && hostPlatform.isGnu && target == aarch64-unknown-linux-gnu
    then pkgs
    else if hostPlatform.isAarch64 && hostPlatform.isLinux && target == aarch64-unknown-linux-musl
    then
      if hostPlatform.isMusl
      then pkgs
      else pkgs.pkgsCross.aarch64-multiplatform-musl
    else if hostPlatform.isx86_64 && hostPlatform.isLinux && hostPlatform.isGnu && target == x86_64-unknown-linux-gnu
    then pkgs
    else if hostPlatform.isx86_64 && hostPlatform.isLinux && target == x86_64-unknown-linux-musl
    then
      if hostPlatform.isMusl
      then pkgs
      else pkgs.pkgsCross.musl64
    else if hostPlatform.isx86_64 && hostPlatform.isWindows && target == x86_64-pc-windows-gnu
    then pkgs
    else if target == aarch64-unknown-linux-gnu
    then pkgs.pkgsCross.aarch64-multiplatform
    else if target == aarch64-unknown-linux-musl
    then pkgs.pkgsCross.aarch64-multiplatform-musl
    else if target == aarch64-apple-darwin
    then pkgs.pkgsCross.aarch64-darwin
    else if target == armv7-unknown-linux-musleabihf
    then pkgs.pkgsCross.armv7l-hf-multiplatform
    else if target == x86_64-apple-darwin
    then pkgs.pkgsCross.x86_64-darwin
    else if target == x86_64-pc-windows-gnu
    then pkgs.pkgsCross.mingwW64
    else if target == x86_64-unknown-linux-gnu
    then pkgs.pkgsCross.gnu64
    else if target == x86_64-unknown-linux-musl
    then pkgs.pkgsCross.musl64
    else if target == wasm32-unknown-unknown || target == wasm32-wasi
    then pkgs.pkgsCross.wasi32
    else
      import nixpkgs {
        crossSystem = target;
        localSystem = hostPlatform.system;
      }
