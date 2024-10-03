# constructs a package set for specified `target` given `pkgs`.
{
  self,
  flake-utils,
  nixpkgs-darwin,
  nixpkgs-nixos,
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
    else if hostPlatform.isAarch64 && hostPlatform.isLinux && hostPlatform.isAndroid && target == aarch64-linux-android
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
    else if target == aarch64-apple-darwin
    then pkgs.pkgsCross.aarch64-darwin
    else if target == aarch64-apple-ios
    then pkgs.pkgsCross.iphone64
    else if target == aarch64-linux-android
    then pkgs.pkgsCross.aarch64-android-prebuilt
    else if target == aarch64-unknown-linux-gnu
    then pkgs.pkgsCross.aarch64-multiplatform
    else if target == aarch64-unknown-linux-musl
    then pkgs.pkgsCross.aarch64-multiplatform-musl
    else if target == arm-unknown-linux-gnueabihf
    then pkgs.pkgsCross.raspberryPi
    else if target == arm-unknown-linux-musleabihf
    then pkgs.pkgsCross.muslpi
    else if target == armv7s-apple-ios
    then pkgs.pkgsCross.iphone32
    else if target == armv7-unknown-linux-musleabihf
    then pkgs.pkgsCross.armv7l-hf-multiplatform
    else if target == armv7-unknown-linux-gnueabihf
    then pkgs.pkgsCross.armv7l-hf-multiplatform
    else if target == mips-unknown-linux-gnu
    then pkgs.pkgsCross.mips-linux-gnu
    else if target == mipsel-unknown-linux-gnu
    then pkgs.pkgsCross.mipsel-linux-gnu
    else if target == mips64-unknown-linux-gnuabi64
    then pkgs.pkgsCross.mips64-linux-gnuabi64
    else if target == mips64el-unknown-linux-gnuabi64
    then pkgs.pkgsCross.mips64el-linux-gnuabi64
    else if target == powerpc64-unknown-linux-gnu
    then pkgs.pkgsCross.ppc64
    else if target == powerpc64-unknown-linux-musl
    then pkgs.pkgsCross.ppc64-musl
    else if target == powerpc64le-unknown-linux-gnu
    then pkgs.pkgsCross.powernv
    else if target == powerpc64le-unknown-linux-musl
    then pkgs.pkgsCross.musl-power
    else if target == riscv64gc-unknown-linux-gnu
    then pkgs.pkgsCross.riscv64
    else if target == s390x-unknown-linux-gnu
    then pkgs.pkgsCross.s390x
    else if target == s390x-unknown-linux-musl
    then pkgs.pkgsCross.s390x
    else if target == x86_64-apple-darwin
    then pkgs.pkgsCross.x86_64-darwin
    else if target == x86_64-apple-ios
    then pkgs.pkgsCross.iphone64-simulator
    else if target == x86_64-pc-windows-gnu
    then pkgs.pkgsCross.mingwW64
    else if target == x86_64-unknown-linux-gnu
    then pkgs.pkgsCross.gnu64
    else if target == x86_64-unknown-linux-musl
    then pkgs.pkgsCross.musl64
    else if target == wasm32-unknown-unknown || target == wasm32-wasip1
    then pkgs.pkgsCross.wasi32
    else
      import (
        if pkgs.stdenv.buildPlatform.isDarwin
        then nixpkgs-darwin
        else nixpkgs-nixos
      ) {
        crossSystem.config =
          if target == riscv64gc-unknown-linux-musl
          then "riscv64-unknown-linux-musl"
          else target;
        localSystem = hostPlatform.system;
      }
