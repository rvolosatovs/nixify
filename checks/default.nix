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
      system:
        assert flake.checks.${system} ? clippy;
        assert flake.checks.${system} ? fmt;
        assert flake.checks.${system} ? nextest;
        assert flake.devShells.${system} ? default;
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

  flakes.rust.bindeps = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-bindeps;
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

  flakes.rust.exclude-path = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-exclude-path;
    excludePaths = [
      "tests/exclude.rs"
    ];
  };

  flakes.rust.unsupported-target = rust.mkFlake {
    inherit
      overlays
      withPackages
      ;

    src = ../examples/rust-unsupported-target;
    targets.x86_64-unknown-none = false;
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
  in
    # TODO: Support cross-compilation to Linux from Darwin
    assert flakes.rust.hello.packages.${system} ? "default";
    assert flakes.rust.hello.packages.${system} ? "rust-hello";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-aarch64-apple-darwin-oci" || !isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-aarch64-unknown-linux-musl-oci" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-wasm32-wasi";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-wasm32-wasi-oci";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-x86_64-apple-darwin-oci" || system != x86_64-darwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-x86_64-unknown-linux-musl-oci" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-aarch64-apple-darwin-oci" || !isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-aarch64-unknown-linux-musl-oci" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-wasm32-wasi";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-wasm32-wasi-oci";
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-x86_64-apple-darwin-oci" || system != x86_64-darwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello.packages.${system} ? "rust-hello-debug-x86_64-unknown-linux-musl-oci" || isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "default";
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin";
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-wasm32-wasi";
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug";
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug-wasm32-wasi";
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.hello-multibin.packages.${system} ? "rust-hello-multibin-debug-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib";
    assert flakes.rust.lib.checks.${system} ? "rust-lib-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-wasm32-wasi";
    assert flakes.rust.lib.checks.${system} ? "rust-lib-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug";
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug-wasm32-wasi";
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.lib.checks.${system} ? "rust-lib-debug-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.unsupported-target.packages.${system} ? "default";
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target";
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target-aarch64-apple-darwin" || system != aarch64-darwin;
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target-debug";
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target-debug-aarch64-apple-darwin" || system != aarch64-darwin;
    assert flakes.rust.unsupported-target.packages.${system} ? "rust-unsupported-target-debug-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.workspace.packages.${system} ? "default";
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace";
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-wasm32-wasi";
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-x86_64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug";
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug-aarch64-apple-darwin" || !isDarwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug-aarch64-unknown-linux-musl" || isDarwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug-wasm32-wasi";
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug-x86_64-apple-darwin" || system != x86_64-darwin;
    assert flakes.rust.workspace.packages.${system} ? "rust-workspace-debug-x86_64-unknown-linux-musl" || isDarwin;
      foldl (checks: example: checks // (assertRustOutputs flakes.rust.${example} "rust-${example}" system)) {} (attrNames flakes.rust))
