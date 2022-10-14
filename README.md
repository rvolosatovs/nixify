# Description

Simple, yet extensible nix flake bootstrapping library for real-world projects

# Usage

See `examples` directory

## Rust

### Template

To nixify a Rust project:
```
nix flake init --template 'github:rvolosatovs/nixify#rust'
```

### Example

A flake definition at `examples/rust-hello/flake.nix`:
```nix
{
  inputs.nixify.url = github:rvolosatovs/nixify;

  description = "Rust hello world";

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;
      ignorePaths = [
        "/.gitignore"
        "/flake.lock"
        "/flake.nix"
        "/rust-toolchain.toml"
      ];
    };
}
```

Produces the following outputs (`nix flake show 'github:rvolosatovs/nixify?dir=examples/rust-hello'`):
```
├───checks
│   ├───aarch64-darwin
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   ├───aarch64-linux
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   ├───powerpc64le-linux
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   ├───x86_64-darwin
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   └───x86_64-linux
│       ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│       ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│       └───nextest: derivation 'rust-hello-nextest-0.1.0'
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'nix-shell'
│   ├───aarch64-linux
│   │   └───default: development environment 'nix-shell'
│   ├───powerpc64le-linux
│   │   └───default: development environment 'nix-shell'
│   ├───x86_64-darwin
│   │   └───default: development environment 'nix-shell'
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   ├───aarch64-darwin: package 'alejandra-1.4.0'
│   ├───aarch64-linux: package 'alejandra-1.4.0'
│   ├───powerpc64le-linux: package 'alejandra-1.4.0'
│   ├───x86_64-darwin: package 'alejandra-1.4.0'
│   └───x86_64-linux: package 'alejandra-1.4.0'
├───overlays
│   └───default: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
    │   └───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    ├───aarch64-linux
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-x86_64-unknown-linux-gnu-0.1.0'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-x86_64-unknown-linux-gnu-0.1.0'
    │   └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    ├───powerpc64le-linux
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-aarch64-unknown-linux-gnu-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-aarch64-unknown-linux-gnu-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-x86_64-unknown-linux-gnu-0.1.0'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-x86_64-unknown-linux-gnu-0.1.0'
    │   └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    ├───x86_64-darwin
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin: package 'rust-hello-aarch64-apple-darwin-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin: package 'rust-hello-aarch64-apple-darwin-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-apple-darwin: package 'rust-hello-0.1.0'
    │   └───rust-hello-x86_64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    └───x86_64-linux
        ├───default: package 'rust-hello-0.1.0'
        ├───rust-hello: package 'rust-hello-0.1.0'
        ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-aarch64-unknown-linux-gnu-0.1.0'
        ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-aarch64-unknown-linux-gnu-0.1.0'
        ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
        ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-wasm32-wasi: package 'rust-hello-static-wasm32-unknown-wasi-0.1.0'
        ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
        └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
```
