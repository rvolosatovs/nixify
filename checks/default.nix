{
  self,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib; let
  rust-hello-flake = self.lib.rust.mkFlake {
    src = "${self}/examples/rust-hello";

    withPackages = {
      pkgs,
      packages,
      ...
    }:
      packages
      // {
        hello = pkgs.hello;
      };
  };
in
  genAttrs [
    aarch64-darwin
    aarch64-linux
    x86_64-darwin
    x86_64-linux
  ] (
    system:
      (with rust-hello-flake.checks.${system}; {
        rust-hello-check-clippy = clippy;
        rust-hello-check-fmt = fmt;
        rust-hello-check-nextest = nextest;
      })
      // (with rust-hello-flake.devShells.${system}; {
        rust-hello-shell-default = default;
      })
      // (with rust-hello-flake.packages.${system};
        {
          rust-hello-pkg-hello = hello;

          rust-hello-pkg-default = default;

          rust-hello-pkg-rust-hello = rust-hello;
          rust-hello-pkg-rust-hello-debug = rust-hello-debug;
        }
        # TODO: Remove
        // optionalAttrs (system != aarch64-darwin && system != x86_64-darwin) {
          rust-hello-pkg-rust-hello-aarch64-unknown-linux-musl = rust-hello-aarch64-unknown-linux-musl;
          rust-hello-pkg-rust-hello-aarch64-unknown-linux-musl-oci = rust-hello-aarch64-unknown-linux-musl-oci;
          rust-hello-pkg-rust-hello-wasm32-wasi = rust-hello-wasm32-wasi;
          rust-hello-pkg-rust-hello-wasm32-wasi-oci = rust-hello-wasm32-wasi-oci;
          rust-hello-pkg-rust-hello-x86_64-unknown-linux-musl = rust-hello-x86_64-unknown-linux-musl;
          rust-hello-pkg-rust-hello-x86_64-unknown-linux-musl-oci = rust-hello-x86_64-unknown-linux-musl-oci;

          rust-hello-pkg-rust-hello-debug-aarch64-unknown-linux-musl = rust-hello-debug-aarch64-unknown-linux-musl;
          rust-hello-pkg-rust-hello-debug-aarch64-unknown-linux-musl-oci = rust-hello-debug-aarch64-unknown-linux-musl-oci;
          rust-hello-pkg-rust-hello-debug-wasm32-wasi = rust-hello-debug-wasm32-wasi;
          rust-hello-pkg-rust-hello-debug-wasm32-wasi-oci = rust-hello-debug-wasm32-wasi-oci;
          rust-hello-pkg-rust-hello-debug-x86_64-unknown-linux-musl = rust-hello-debug-x86_64-unknown-linux-musl;
          rust-hello-pkg-rust-hello-debug-x86_64-unknown-linux-musl-oci = rust-hello-debug-x86_64-unknown-linux-musl-oci;
        }
        # TODO: Support x86_64 -> aarch64 cross
        // optionalAttrs (system == aarch64-darwin) {
          rust-hello-pkg-rust-hello-aarch64-apple-darwin = rust-hello-aarch64-apple-darwin;
          rust-hello-pkg-rust-hello-aarch64-apple-darwin-oci = rust-hello-aarch64-apple-darwin-oci;

          rust-hello-pkg-rust-hello-debug-aarch64-apple-darwin = rust-hello-debug-aarch64-apple-darwin;
          rust-hello-pkg-rust-hello-debug-aarch64-apple-darwin-oci = rust-hello-debug-aarch64-apple-darwin-oci;
        }
        // optionalAttrs (system == x86_64-darwin) {
          rust-hello-pkg-rust-hello-x86_64-apple-darwin = rust-hello-x86_64-apple-darwin;
          rust-hello-pkg-rust-hello-x86_64-apple-darwin-oci = rust-hello-x86_64-apple-darwin-oci;

          rust-hello-pkg-rust-hello-debug-x86_64-apple-darwin = rust-hello-debug-x86_64-apple-darwin;
          rust-hello-pkg-rust-hello-debug-x86_64-apple-darwin-oci = rust-hello-debug-x86_64-apple-darwin-oci;
        })
  )
