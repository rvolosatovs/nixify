{
  self,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
with self.lib; let
  assertRustOutputs = flake: name:
    assert name != "default";
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
      system:
        assert flake.checks.${system} ? clippy;
        assert flake.checks.${system} ? fmt;
        assert flake.checks.${system} ? nextest;
        assert flake.devShells.${system} ? default;
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
    };

  flakes.rust.complex = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-complex;

    targets.wasm32-wasi = false; # https://github.com/briansmith/ring/issues/1043
  };

  flakes.rust.hello = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-hello;
  };

  flakes.rust.hello-multibin = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-hello-multibin;
  };

  flakes.rust.lib = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-lib;
    cargoLock = ../examples/rust-lib/Cargo.test.lock;
  };

  flakes.rust.workspace = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-workspace;
    name = "rust-workspace";
  };
in
  genAttrs [
    aarch64-darwin
    aarch64-linux
    x86_64-darwin
    x86_64-linux
  ]
  (system: let
    isDarwin = system == aarch64-darwin || system == x86_64-darwin;
    assertRustPackages = attrs: name: x:
      assert attrs.${system} ? "${name}-aarch64-apple-darwin" || !isDarwin;
      assert attrs.${system} ? "${name}-aarch64-unknown-linux-musl";
      assert attrs.${system} ? "${name}-armv7-unknown-linux-musleabihf";
      assert attrs.${system} ? "${name}-x86_64-apple-darwin" || system != x86_64-darwin;
      assert attrs.${system} ? "${name}-x86_64-pc-windows-gnu";
      assert attrs.${system} ? "${name}-x86_64-unknown-linux-musl";
      assert attrs.${system} ? ${name}; x;
    assertRustOCIPackages = attrs: name: x:
      assert attrs.${system} ? "${name}-aarch64-apple-darwin-oci" || !isDarwin;
      assert attrs.${system} ? "${name}-aarch64-unknown-linux-musl-oci";
      assert attrs.${system} ? "${name}-armv7-unknown-linux-musleabihf-oci";
      assert attrs.${system} ? "${name}-x86_64-apple-darwin-oci" || system != x86_64-darwin;
      assert attrs.${system} ? "${name}-x86_64-pc-windows-gnu-oci";
      assert attrs.${system} ? "${name}-x86_64-unknown-linux-musl-oci"; x;
  in
    assert flakes.rust.complex.packages.${system} ? default;
    assert flakes.rust.hello-multibin.packages.${system} ? default;
    assert flakes.rust.hello-multibin.packages.${system} ? rust-hello-multibin-wasm32-wasi;
    assert flakes.rust.hello.packages.${system} ? default;
    assert flakes.rust.hello.packages.${system} ? rust-hello-wasm32-wasi-oci;
    assert flakes.rust.hello.packages.${system} ? rust-hello-wasm32-wasi;
    assert flakes.rust.lib.checks.${system} ? rust-lib-wasm32-wasi;
    assert flakes.rust.workspace.packages.${system} ? default;
    assert flakes.rust.workspace.packages.${system} ? rust-workspace-wasm32-wasi;
      (assertRustPackages flakes.rust.complex.packages "rust-complex")
      (assertRustPackages flakes.rust.hello-multibin.packages "rust-hello-multibin")
      (assertRustPackages flakes.rust.hello.packages "rust-hello")
      (assertRustPackages flakes.rust.lib.checks "rust-lib")
      (assertRustPackages flakes.rust.workspace.packages "rust-workspace")
      (assertRustOCIPackages flakes.rust.complex.packages "rust-complex")
      (assertRustOCIPackages flakes.rust.hello.packages "rust-hello")
      foldl (checks: example: checks // (assertRustOutputs flakes.rust.${example} "rust-${example}" system)) {} (attrNames flakes.rust))
