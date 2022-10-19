{
  self,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib; let
  assertRustOutputs = flake: name:
    assert name != "default";
    assert name != "hello";
    assert name != "rust";
    assert name != "test-final";
    assert name != "test-prev";
    assert flake ? checks;
    assert flake ? devShells;
    assert flake ? overlays;
    assert flake ? packages;
    assert flake.overlays ? "${name}";
    assert flake.overlays ? default;
    assert flake.overlays ? rust;
      system: let
        isDarwin = system == aarch64-darwin || system == x86_64-darwin;
      in
        # TODO: Support cross-compilation to Linux from Darwin
        assert flake.checks.${system} ? clippy;
        assert flake.checks.${system} ? fmt;
        assert flake.checks.${system} ? nextest;
        assert flake.devShells.${system} ? default;
        assert flake.packages.${system} ? "${name}";
        assert flake.packages.${system} ? "${name}-aarch64-apple-darwin" || !isDarwin;
        assert flake.packages.${system} ? "${name}-aarch64-apple-darwin-oci" || !isDarwin;
        assert flake.packages.${system} ? "${name}-aarch64-unknown-linux-musl" || isDarwin;
        assert flake.packages.${system} ? "${name}-aarch64-unknown-linux-musl-oci" || isDarwin;
        assert flake.packages.${system} ? "${name}-wasm32-wasi";
        assert flake.packages.${system} ? "${name}-wasm32-wasi-oci";
        assert flake.packages.${system} ? "${name}-x86_64-apple-darwin" || system != x86_64-darwin;
        assert flake.packages.${system} ? "${name}-x86_64-apple-darwin-oci" || system != x86_64-darwin;
        assert flake.packages.${system} ? "${name}-x86_64-unknown-linux-musl" || isDarwin;
        assert flake.packages.${system} ? "${name}-x86_64-unknown-linux-musl-oci" || isDarwin;
        assert flake.packages.${system} ? "${name}-debug";
        assert flake.packages.${system} ? "${name}-debug-aarch64-apple-darwin" || !isDarwin;
        assert flake.packages.${system} ? "${name}-debug-aarch64-apple-darwin-oci" || !isDarwin;
        assert flake.packages.${system} ? "${name}-debug-aarch64-unknown-linux-musl" || isDarwin;
        assert flake.packages.${system} ? "${name}-debug-aarch64-unknown-linux-musl-oci" || isDarwin;
        assert flake.packages.${system} ? "${name}-debug-wasm32-wasi";
        assert flake.packages.${system} ? "${name}-debug-wasm32-wasi-oci";
        assert flake.packages.${system} ? "${name}-debug-x86_64-apple-darwin" || system != x86_64-darwin;
        assert flake.packages.${system} ? "${name}-debug-x86_64-apple-darwin-oci" || system != x86_64-darwin;
        assert flake.packages.${system} ? "${name}-debug-x86_64-unknown-linux-musl" || isDarwin;
        assert flake.packages.${system} ? "${name}-debug-x86_64-unknown-linux-musl-oci" || isDarwin;
        assert flake.packages.${system} ? default;
        assert flake.packages.${system} ? hello;
        assert flake.packages.${system} ? test-final;
        assert flake.packages.${system} ? test-prev;
          mapAttrs' (n: nameValuePair "${name}-check-${n}") flake.checks.${system}
          // mapAttrs' (n: nameValuePair "${name}-shell-${n}") flake.devShells.${system}
          // mapAttrs' (n: nameValuePair "${name}-package-${n}") flake.packages.${system};

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
    assertRustOutputs rust-hello-flake "rust-hello"
  )
