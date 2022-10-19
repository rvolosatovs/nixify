{
  self,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib; let
  overlays = [
    (final: prev: {
      test-prev = final.test-final;
    })
    (final: prev: {
      test-final = final.writeText "test" "test";
    })
  ];

  withPackages = {
    pkgs,
    packages,
    ...
  }:
    packages
    // {
      test-prev = pkgs.test-prev;
      test-final = pkgs.test-final;
      hello = pkgs.hello;
    };

  rust-hello-flake = self.lib.rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-hello;
  };
in
  genAttrs [
    aarch64-darwin
    aarch64-linux
    x86_64-darwin
    x86_64-linux
  ] (
    system: let
      isDarwin = system == aarch64-darwin || system == x86_64-darwin;
    in
      # TODO: Support cross-compilation to Linux from Darwin
      assert rust-hello-flake.checks.${system} ? clippy;
      assert rust-hello-flake.checks.${system} ? fmt;
      assert rust-hello-flake.checks.${system} ? nextest;
      assert rust-hello-flake.devShells.${system} ? default;
      assert rust-hello-flake.packages.${system} ? default;
      assert rust-hello-flake.packages.${system} ? hello;
      assert rust-hello-flake.packages.${system} ? rust-hello-aarch64-apple-darwin || !isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-aarch64-apple-darwin-oci || !isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-aarch64-unknown-linux-musl || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-aarch64-unknown-linux-musl-oci || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-aarch64-apple-darwin || !isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-aarch64-apple-darwin-oci || !isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-aarch64-unknown-linux-musl || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-aarch64-unknown-linux-musl-oci || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-wasm32-wasi-oci;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-wasm32-wasi;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-x86_64-apple-darwin || system != x86_64-darwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-x86_64-apple-darwin-oci || system != x86_64-darwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-x86_64-unknown-linux-musl || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug-x86_64-unknown-linux-musl-oci || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-debug;
      assert rust-hello-flake.packages.${system} ? rust-hello-wasm32-wasi-oci;
      assert rust-hello-flake.packages.${system} ? rust-hello-wasm32-wasi;
      assert rust-hello-flake.packages.${system} ? rust-hello-x86_64-apple-darwin || system != x86_64-darwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-x86_64-apple-darwin-oci || system != x86_64-darwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-x86_64-unknown-linux-musl || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello-x86_64-unknown-linux-musl-oci || isDarwin;
      assert rust-hello-flake.packages.${system} ? rust-hello;
      assert rust-hello-flake.packages.${system} ? test-final;
      assert rust-hello-flake.packages.${system} ? test-prev;
        mapAttrs' (n: nameValuePair "rust-hello-check-${n}") rust-hello-flake.checks.${system}
        // mapAttrs' (n: nameValuePair "rust-hello-shell-${n}") rust-hello-flake.devShells.${system}
        // mapAttrs' (n: nameValuePair "rust-hello-package-${n}") rust-hello-flake.packages.${system}
  )
