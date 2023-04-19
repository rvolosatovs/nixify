# Description

Simple, yet extensible, batteries-included Nix flake bootstrapping library for real-world projects with focus on building reproducible, portable binary artifacts for various targets efficiently and with little to no configuration.

# Features

- 0-config reproducible, portable binary artifacts
    - Cross-compilation out-of-the-box
    - Tiny OCI (Docker) images with statically-linked binaries out-of-the-box
- Automatic per-system flake generation from a shared definition with consistent API
- Source filtering

# Usage

## Generic flakes

`nixify.lib.mkFlake` provides the flake construction functionality that all other language specific subsystems rely upon. It can be used to build a plain Nix flake or a generic project in your language of choice.

### Examples

- https://github.com/rvolosatovs/nix-log/blob/main/flake.nix
- https://github.com/rvolosatovs/nix-modulate/blob/main/flake.nix
- https://github.com/rvolosatovs/nixify/blob/main/flake.nix

## Rust

`nixify` relies on two files to "Nixify" Rust projects:
- `Cargo.toml` (required), where `pname` and `version` will be taken from. Note, that virtual manifests are supported as well.
- `rust-toolchain.toml` (optional). If exists, `nixify` will set up the Rust toolchain using data contained in this file. For cross-compilation scenarios, `nixify` will automatically add missing targets to the toolchain.

### Cross-compilation

- `aarch64-darwin` -> `aarch64-apple-darwin`
- `aarch64-darwin` -> `aarch64-linux-musl`
- `aarch64-darwin` -> `armv7-unknown-linux-musleabihf`
- `aarch64-darwin` -> `wasm32-wasi`
- `aarch64-darwin` -> `x86_64-linux-musl`
- `aarch64-darwin` -> `x86_64-pc-windows-gnu`

- `aarch64-linux` -> `aarch64-linux-musl`
- `aarch64-linux` -> `armv7-unknown-linux-musleabihf`
- `aarch64-linux` -> `wasm32-wasi`
- `aarch64-linux` -> `x86_64-linux-musl`
- `aarch64-linux` -> `x86_64-pc-windows-gnu`

- `x86_64-darwin` -> `aarch64-apple-darwin`
- `x86_64-darwin` -> `aarch64-linux-musl`
- `x86_64-darwin` -> `armv7-unknown-linux-musleabihf`
- `x86_64-darwin` -> `wasm32-wasi`
- `x86_64-darwin` -> `x86_64-apple-darwin`
- `x86_64-darwin` -> `x86_64-linux-musl`
- `x86_64-darwin` -> `x86_64-pc-windows-gnu`

- `x86_64-linux` -> `aarch64-linux-musl`
- `x86_64-linux` -> `armv7-unknown-linux-musleabihf`
- `x86_64-linux` -> `wasm32-wasi`
- `x86_64-linux` -> `x86_64-linux-musl`
- `x86_64-linux` -> `x86_64-pc-windows-gnu`

### Template

To nixify a Rust project:
```
nix flake init --template 'github:rvolosatovs/nixify#rust'
```

### Examples

- https://github.com/bytecodealliance/wit-deps/blob/main/flake.nix
- https://github.com/wasmcloud/wasmcloud/blob/main/flake.nix
- https://github.com/profianinc/drawbridge/blob/main/flake.nix
- https://github.com/profianinc/steward/blob/main/flake.nix

A flake definition at `examples/rust-hello/flake.nix`:
```nix
{
  inputs.nixify.url = github:rvolosatovs/nixify;

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;
    };
}
```

Produces the following outputs:

```
$ nix flake show --no-write-lock-file 'github:rvolosatovs/nixify?dir=examples/rust-hello'
<...>
├───apps
│   ├───aarch64-darwin
│   │   ├───default: app
│   │   ├───rust-hello: app
│   │   └───rust-hello-debug: app
│   ├───aarch64-linux
│   │   ├───default: app
│   │   ├───rust-hello: app
│   │   └───rust-hello-debug: app
│   ├───x86_64-darwin
│   │   ├───default: app
│   │   ├───rust-hello: app
│   │   └───rust-hello-debug: app
│   └───x86_64-linux
│       ├───default: app
│       ├───rust-hello: app
│       └───rust-hello-debug: app
├───checks
│   ├───aarch64-darwin
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───doc: derivation 'rust-hello-doc-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   ├───aarch64-linux
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───doc: derivation 'rust-hello-doc-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   ├───x86_64-darwin
│   │   ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│   │   ├───doc: derivation 'rust-hello-doc-0.1.0'
│   │   ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│   │   └───nextest: derivation 'rust-hello-nextest-0.1.0'
│   └───x86_64-linux
│       ├───clippy: derivation 'rust-hello-clippy-0.1.0'
│       ├───doc: derivation 'rust-hello-doc-0.1.0'
│       ├───fmt: derivation 'rust-hello-fmt-0.1.0'
│       └───nextest: derivation 'rust-hello-nextest-0.1.0'
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'nix-shell'
│   ├───aarch64-linux
│   │   └───default: development environment 'nix-shell'
│   ├───x86_64-darwin
│   │   └───default: development environment 'nix-shell'
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   ├───aarch64-darwin: package 'alejandra-3.0.0'
│   ├───aarch64-linux: package 'alejandra-3.0.0'
│   ├───x86_64-darwin: package 'alejandra-3.0.0'
│   └───x86_64-linux: package 'alejandra-3.0.0'
├───overlays
│   ├───default: Nixpkgs overlay
│   ├───rust: Nixpkgs overlay
│   └───rust-hello: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    ├───aarch64-linux
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    ├───x86_64-darwin
    │   ├───default: package 'rust-hello-0.1.0'
    │   ├───rust-hello: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
    │   ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-apple-darwin: package 'rust-hello-0.1.0'
    │   ├───rust-hello-x86_64-apple-darwin-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
    │   ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
    │   └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
    └───x86_64-linux
        ├───default: package 'rust-hello-0.1.0'
        ├───rust-hello: package 'rust-hello-0.1.0'
        ├───rust-hello-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
        ├───rust-hello-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
        ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-aarch64-unknown-linux-musl: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-wasm32-wasi: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-debug-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
        ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-wasm32-wasi: package 'rust-hello-0.1.0'
        ├───rust-hello-wasm32-wasi-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-x86_64-pc-windows-gnu: package 'rust-hello-0.1.0'
        ├───rust-hello-x86_64-pc-windows-gnu-oci: package 'docker-image-rust-hello.tar.gz'
        ├───rust-hello-x86_64-unknown-linux-musl: package 'rust-hello-0.1.0'
        └───rust-hello-x86_64-unknown-linux-musl-oci: package 'docker-image-rust-hello.tar.gz'
```
