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

|                                      | `aarch64-darwin` | `aarch64-linux` | `x86_64-darwin` | `x86_64-linux` |
|:------------------------------------:|:----------------:|:---------------:|:---------------:|:--------------:|
|      **`aarch64-apple-darwin`**      |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|    **`aarch64-unknown-linux-gnu`**   |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|   **`aarch64-unknown-linux-musl`**   |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|      **`aarch64-linux-android`**     |         ❌        |        ❌        |        ❌        |        ✔️       |
| **`arm-unknown-linux-gnueabihf`**    |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`arm-unknown-linux-musleabihf`**   |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`armv7-unknown-linux-gnueabihf`**  |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`armv7-unknown-linux-musleabihf`** |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`powerpc64le-unknown-linux-gnu`**  |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`riscv64gc-unknown-linux-gnu`**    |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
| **`s390x-unknown-linux-gnu`**        |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|     **`wasm32-unknown-unknown`**     |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|         **`wasm32-wasip1`**          |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|         **`wasm32-wasip2`**          |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|       **`x86_64-apple-darwin`**      |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|      **`x86_64-pc-windows-gnu`**     |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|    **`x86_64-unknown-linux-gnu`**    |         ✔️        |        ✔️        |        ✔️        |        ✔️       |
|    **`x86_64-unknown-linux-musl`**   |         ✔️        |        ✔️        |        ✔️        |        ✔️       |

Additional targets (e.g. `aarch64-apple-ios`, `mips*`, `powerpc*-musl`, `riscv64gc-unknown-linux-musl`, `s390x-unknown-linux-musl`) are wired through `lib/rust/defaultPkgsFor.nix` and `lib/rust/default.nix`'s `targets` attrset, but are not exercised in CI.

### Template

To nixify a Rust project:
```
nix flake init --template 'github:rvolosatovs/nixify#rust'
```

### Examples

In-tree, exercised by `nix flake check`:

- [`examples/rust-hello`](examples/rust-hello) — single-binary crate with the full cross-compilation matrix
- [`examples/rust-hello-multibin`](examples/rust-hello-multibin) — multiple binaries from one crate
- [`examples/rust-complex`](examples/rust-complex) — non-trivial crate with build-time deps
- [`examples/rust-lib`](examples/rust-lib) — library crate (no binaries)
- [`examples/rust-workspace`](examples/rust-workspace) — Cargo workspace

External:

- https://github.com/bytecodealliance/wit-deps/blob/main/flake.nix
- https://github.com/profianinc/drawbridge/blob/main/flake.nix
- https://github.com/profianinc/steward/blob/main/flake.nix

A flake definition at `examples/rust-hello/flake.nix`:
```nix
{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs =
    { self, nixify, ... }:
    nixify.lib.rust.mkFlake {
      src = self;

      nixpkgsConfig.allowUnfree = true;

      targets.aarch64-apple-darwin = true;
      targets.aarch64-linux-android = true;
      targets.aarch64-unknown-linux-gnu = true;
      targets.aarch64-unknown-linux-musl = true;
      targets.arm-unknown-linux-gnueabihf = true;
      targets.arm-unknown-linux-musleabihf = true;
      targets.armv7-unknown-linux-gnueabihf = true;
      targets.armv7-unknown-linux-musleabihf = true;
      targets.powerpc64le-unknown-linux-gnu = true;
      targets.riscv64gc-unknown-linux-gnu = true;
      targets.s390x-unknown-linux-gnu = true;
      targets.wasm32-unknown-unknown = true;
      targets.wasm32-wasip2 = true;
      targets.x86_64-apple-darwin = true;
      targets.x86_64-pc-windows-gnu = true;
      targets.x86_64-unknown-linux-gnu = true;
      targets.x86_64-unknown-linux-musl = true;
    };
}
```

Produces the following outputs (per system):

- `apps.<system>.{default,<pname>,<pname>-debug}` — `nix run` entry points wrapping the host-system binaries.
- `checks.<system>.{audit,clippy,doc,fmt,nextest}` — what `nix flake check` runs (`doctest` is added when `test.allTargets` or `test.doc` is set).
- `devShells.<system>.default` — dev shell with the resolved Rust toolchain on `PATH`.
- `formatter.<system>` — the Nix formatter (`nixfmt`).
- `overlays.{default,<pname>,fenix,rust-overlay}` — re-exported toolchain overlays plus one that adds `<pname>` to nixpkgs.
- `packages.<system>` — per target (`<target>` in the enabled `targets` set), five packages each, in both release and debug flavors:
  - `<pname>[-debug]-<target>` — the binary built for that target.
  - `<pname>[-debug]-<target>-deps` — the prebuilt cargo dependency artifact (cached separately).
  - `<pname>[-debug]-<target>-oci` — a `docker load`-able image tarball.
  - `<pname>[-debug]-<target>-oci-dir` — the same image as an OCI image directory.
  - `<pname>[-debug]-<target>-oci-manifest` — the OCI manifest JSON.
  - Plus host-system aliases: `default`, `<pname>`, `<pname>-debug`, `<pname>-oci`, `<pname>-oci-dir` (target suffix dropped).

<details>
<summary><code>nix flake show --no-write-lock-file --all-systems 'github:rvolosatovs/nixify?dir=examples/rust-hello'</code></summary>

```
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
│   │   ├───audit: CI test
│   │   ├───clippy: CI test
│   │   ├───doc: CI test
│   │   ├───fmt: CI test
│   │   └───nextest: CI test
│   ├───aarch64-linux
│   │   ├───audit: CI test
│   │   ├───clippy: CI test
│   │   ├───doc: CI test
│   │   ├───fmt: CI test
│   │   └───nextest: CI test
│   ├───x86_64-darwin
│   │   ├───audit: CI test
│   │   ├───clippy: CI test
│   │   ├───doc: CI test
│   │   ├───fmt: CI test
│   │   └───nextest: CI test
│   └───x86_64-linux
│       ├───audit: CI test
│       ├───clippy: CI test
│       ├───doc: CI test
│       ├───fmt: CI test
│       └───nextest: CI test
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment
│   ├───aarch64-linux
│   │   └───default: development environment
│   ├───x86_64-darwin
│   │   └───default: development environment
│   └───x86_64-linux
│       └───default: development environment
├───formatter
│   ├───aarch64-darwin: formatter
│   ├───aarch64-linux: formatter
│   ├───x86_64-darwin: formatter
│   └───x86_64-linux: formatter
├───overlays
│   ├───default: Nixpkgs overlay
│   ├───fenix: Nixpkgs overlay
│   ├───rust-hello: Nixpkgs overlay
│   └───rust-overlay: Nixpkgs overlay
└───packages
    ├───aarch64-darwin
    │   ├───default: package
    │   ├───rust-hello: package
    │   ├───rust-hello-aarch64-apple-darwin: package
    │   ├───rust-hello-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-aarch64-linux-android: package
    │   ├───rust-hello-aarch64-linux-android-deps: package
    │   ├───rust-hello-aarch64-linux-android-oci: package
    │   ├───rust-hello-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug: package
    │   ├───rust-hello-debug-aarch64-apple-darwin: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-linux-android: package
    │   ├───rust-hello-debug-aarch64-linux-android-deps: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-wasip2: package
    │   ├───rust-hello-debug-wasm32-wasip2-deps: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-apple-darwin: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-oci: package
    │   ├───rust-hello-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-wasm32-unknown-unknown: package
    │   ├───rust-hello-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-wasm32-wasip2: package
    │   ├───rust-hello-wasm32-wasip2-deps: package
    │   ├───rust-hello-wasm32-wasip2-oci: package
    │   ├───rust-hello-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-x86_64-apple-darwin: package
    │   ├───rust-hello-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci-dir: package
    │   └───rust-hello-x86_64-unknown-linux-musl-oci-manifest: package
    ├───aarch64-linux
    │   ├───default: package
    │   ├───rust-hello: package
    │   ├───rust-hello-aarch64-apple-darwin: package
    │   ├───rust-hello-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-aarch64-linux-android: package
    │   ├───rust-hello-aarch64-linux-android-deps: package
    │   ├───rust-hello-aarch64-linux-android-oci: package
    │   ├───rust-hello-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug: package
    │   ├───rust-hello-debug-aarch64-apple-darwin: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-linux-android: package
    │   ├───rust-hello-debug-aarch64-linux-android-deps: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-wasip2: package
    │   ├───rust-hello-debug-wasm32-wasip2-deps: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-apple-darwin: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-oci: package
    │   ├───rust-hello-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-wasm32-unknown-unknown: package
    │   ├───rust-hello-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-wasm32-wasip2: package
    │   ├───rust-hello-wasm32-wasip2-deps: package
    │   ├───rust-hello-wasm32-wasip2-oci: package
    │   ├───rust-hello-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-x86_64-apple-darwin: package
    │   ├───rust-hello-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci-dir: package
    │   └───rust-hello-x86_64-unknown-linux-musl-oci-manifest: package
    ├───x86_64-darwin
    │   ├───default: package
    │   ├───rust-hello: package
    │   ├───rust-hello-aarch64-apple-darwin: package
    │   ├───rust-hello-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-aarch64-linux-android: package
    │   ├───rust-hello-aarch64-linux-android-deps: package
    │   ├───rust-hello-aarch64-linux-android-oci: package
    │   ├───rust-hello-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug: package
    │   ├───rust-hello-debug-aarch64-apple-darwin: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-deps: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-aarch64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-linux-android: package
    │   ├───rust-hello-debug-aarch64-linux-android-deps: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-dir: package
    │   ├───rust-hello-debug-aarch64-linux-android-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-manifest: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-deps: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-dir: package
    │   ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-manifest: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-debug-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-debug-wasm32-wasip2: package
    │   ├───rust-hello-debug-wasm32-wasip2-deps: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-debug-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-apple-darwin: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-debug-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-dir: package
    │   ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-manifest: package
    │   ├───rust-hello-oci: package
    │   ├───rust-hello-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-deps: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-deps: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-s390x-unknown-linux-gnu: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-deps: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-s390x-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-wasm32-unknown-unknown: package
    │   ├───rust-hello-wasm32-unknown-unknown-deps: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-dir: package
    │   ├───rust-hello-wasm32-unknown-unknown-oci-manifest: package
    │   ├───rust-hello-wasm32-wasip2: package
    │   ├───rust-hello-wasm32-wasip2-deps: package
    │   ├───rust-hello-wasm32-wasip2-oci: package
    │   ├───rust-hello-wasm32-wasip2-oci-dir: package
    │   ├───rust-hello-wasm32-wasip2-oci-manifest: package
    │   ├───rust-hello-x86_64-apple-darwin: package
    │   ├───rust-hello-x86_64-apple-darwin-deps: package
    │   ├───rust-hello-x86_64-apple-darwin-oci: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-dir: package
    │   ├───rust-hello-x86_64-apple-darwin-oci-manifest: package
    │   ├───rust-hello-x86_64-pc-windows-gnu: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-deps: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-pc-windows-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-dir: package
    │   ├───rust-hello-x86_64-unknown-linux-gnu-oci-manifest: package
    │   ├───rust-hello-x86_64-unknown-linux-musl: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-deps: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci: package
    │   ├───rust-hello-x86_64-unknown-linux-musl-oci-dir: package
    │   └───rust-hello-x86_64-unknown-linux-musl-oci-manifest: package
    └───x86_64-linux
        ├───default: package
        ├───rust-hello: package
        ├───rust-hello-aarch64-apple-darwin: package
        ├───rust-hello-aarch64-apple-darwin-deps: package
        ├───rust-hello-aarch64-apple-darwin-oci: package
        ├───rust-hello-aarch64-apple-darwin-oci-dir: package
        ├───rust-hello-aarch64-apple-darwin-oci-manifest: package
        ├───rust-hello-aarch64-linux-android: package
        ├───rust-hello-aarch64-linux-android-deps: package
        ├───rust-hello-aarch64-linux-android-oci: package
        ├───rust-hello-aarch64-linux-android-oci-dir: package
        ├───rust-hello-aarch64-linux-android-oci-manifest: package
        ├───rust-hello-aarch64-unknown-linux-gnu: package
        ├───rust-hello-aarch64-unknown-linux-gnu-deps: package
        ├───rust-hello-aarch64-unknown-linux-gnu-oci: package
        ├───rust-hello-aarch64-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-aarch64-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-aarch64-unknown-linux-musl: package
        ├───rust-hello-aarch64-unknown-linux-musl-deps: package
        ├───rust-hello-aarch64-unknown-linux-musl-oci: package
        ├───rust-hello-aarch64-unknown-linux-musl-oci-dir: package
        ├───rust-hello-aarch64-unknown-linux-musl-oci-manifest: package
        ├───rust-hello-arm-unknown-linux-gnueabihf: package
        ├───rust-hello-arm-unknown-linux-gnueabihf-deps: package
        ├───rust-hello-arm-unknown-linux-gnueabihf-oci: package
        ├───rust-hello-arm-unknown-linux-gnueabihf-oci-dir: package
        ├───rust-hello-arm-unknown-linux-gnueabihf-oci-manifest: package
        ├───rust-hello-arm-unknown-linux-musleabihf: package
        ├───rust-hello-arm-unknown-linux-musleabihf-deps: package
        ├───rust-hello-arm-unknown-linux-musleabihf-oci: package
        ├───rust-hello-arm-unknown-linux-musleabihf-oci-dir: package
        ├───rust-hello-arm-unknown-linux-musleabihf-oci-manifest: package
        ├───rust-hello-armv7-unknown-linux-gnueabihf: package
        ├───rust-hello-armv7-unknown-linux-gnueabihf-deps: package
        ├───rust-hello-armv7-unknown-linux-gnueabihf-oci: package
        ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-dir: package
        ├───rust-hello-armv7-unknown-linux-gnueabihf-oci-manifest: package
        ├───rust-hello-armv7-unknown-linux-musleabihf: package
        ├───rust-hello-armv7-unknown-linux-musleabihf-deps: package
        ├───rust-hello-armv7-unknown-linux-musleabihf-oci: package
        ├───rust-hello-armv7-unknown-linux-musleabihf-oci-dir: package
        ├───rust-hello-armv7-unknown-linux-musleabihf-oci-manifest: package
        ├───rust-hello-debug: package
        ├───rust-hello-debug-aarch64-apple-darwin: package
        ├───rust-hello-debug-aarch64-apple-darwin-deps: package
        ├───rust-hello-debug-aarch64-apple-darwin-oci: package
        ├───rust-hello-debug-aarch64-apple-darwin-oci-dir: package
        ├───rust-hello-debug-aarch64-apple-darwin-oci-manifest: package
        ├───rust-hello-debug-aarch64-linux-android: package
        ├───rust-hello-debug-aarch64-linux-android-deps: package
        ├───rust-hello-debug-aarch64-linux-android-oci: package
        ├───rust-hello-debug-aarch64-linux-android-oci-dir: package
        ├───rust-hello-debug-aarch64-linux-android-oci-manifest: package
        ├───rust-hello-debug-aarch64-unknown-linux-gnu: package
        ├───rust-hello-debug-aarch64-unknown-linux-gnu-deps: package
        ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci: package
        ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-debug-aarch64-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-debug-aarch64-unknown-linux-musl: package
        ├───rust-hello-debug-aarch64-unknown-linux-musl-deps: package
        ├───rust-hello-debug-aarch64-unknown-linux-musl-oci: package
        ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-dir: package
        ├───rust-hello-debug-aarch64-unknown-linux-musl-oci-manifest: package
        ├───rust-hello-debug-arm-unknown-linux-gnueabihf: package
        ├───rust-hello-debug-arm-unknown-linux-gnueabihf-deps: package
        ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci: package
        ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-dir: package
        ├───rust-hello-debug-arm-unknown-linux-gnueabihf-oci-manifest: package
        ├───rust-hello-debug-arm-unknown-linux-musleabihf: package
        ├───rust-hello-debug-arm-unknown-linux-musleabihf-deps: package
        ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci: package
        ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-dir: package
        ├───rust-hello-debug-arm-unknown-linux-musleabihf-oci-manifest: package
        ├───rust-hello-debug-armv7-unknown-linux-gnueabihf: package
        ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-deps: package
        ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci: package
        ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-dir: package
        ├───rust-hello-debug-armv7-unknown-linux-gnueabihf-oci-manifest: package
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf: package
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf-deps: package
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci: package
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-dir: package
        ├───rust-hello-debug-armv7-unknown-linux-musleabihf-oci-manifest: package
        ├───rust-hello-debug-powerpc64le-unknown-linux-gnu: package
        ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-deps: package
        ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci: package
        ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-debug-powerpc64le-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-debug-riscv64gc-unknown-linux-gnu: package
        ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-deps: package
        ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci: package
        ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-debug-riscv64gc-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-debug-s390x-unknown-linux-gnu: package
        ├───rust-hello-debug-s390x-unknown-linux-gnu-deps: package
        ├───rust-hello-debug-s390x-unknown-linux-gnu-oci: package
        ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-debug-s390x-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-debug-wasm32-unknown-unknown: package
        ├───rust-hello-debug-wasm32-unknown-unknown-deps: package
        ├───rust-hello-debug-wasm32-unknown-unknown-oci: package
        ├───rust-hello-debug-wasm32-unknown-unknown-oci-dir: package
        ├───rust-hello-debug-wasm32-unknown-unknown-oci-manifest: package
        ├───rust-hello-debug-wasm32-wasip2: package
        ├───rust-hello-debug-wasm32-wasip2-deps: package
        ├───rust-hello-debug-wasm32-wasip2-oci: package
        ├───rust-hello-debug-wasm32-wasip2-oci-dir: package
        ├───rust-hello-debug-wasm32-wasip2-oci-manifest: package
        ├───rust-hello-debug-x86_64-apple-darwin: package
        ├───rust-hello-debug-x86_64-apple-darwin-deps: package
        ├───rust-hello-debug-x86_64-apple-darwin-oci: package
        ├───rust-hello-debug-x86_64-apple-darwin-oci-dir: package
        ├───rust-hello-debug-x86_64-apple-darwin-oci-manifest: package
        ├───rust-hello-debug-x86_64-pc-windows-gnu: package
        ├───rust-hello-debug-x86_64-pc-windows-gnu-deps: package
        ├───rust-hello-debug-x86_64-pc-windows-gnu-oci: package
        ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-dir: package
        ├───rust-hello-debug-x86_64-pc-windows-gnu-oci-manifest: package
        ├───rust-hello-debug-x86_64-unknown-linux-gnu: package
        ├───rust-hello-debug-x86_64-unknown-linux-gnu-deps: package
        ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci: package
        ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-debug-x86_64-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-debug-x86_64-unknown-linux-musl: package
        ├───rust-hello-debug-x86_64-unknown-linux-musl-deps: package
        ├───rust-hello-debug-x86_64-unknown-linux-musl-oci: package
        ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-dir: package
        ├───rust-hello-debug-x86_64-unknown-linux-musl-oci-manifest: package
        ├───rust-hello-oci: package
        ├───rust-hello-oci-dir: package
        ├───rust-hello-powerpc64le-unknown-linux-gnu: package
        ├───rust-hello-powerpc64le-unknown-linux-gnu-deps: package
        ├───rust-hello-powerpc64le-unknown-linux-gnu-oci: package
        ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-powerpc64le-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-riscv64gc-unknown-linux-gnu: package
        ├───rust-hello-riscv64gc-unknown-linux-gnu-deps: package
        ├───rust-hello-riscv64gc-unknown-linux-gnu-oci: package
        ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-riscv64gc-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-s390x-unknown-linux-gnu: package
        ├───rust-hello-s390x-unknown-linux-gnu-deps: package
        ├───rust-hello-s390x-unknown-linux-gnu-oci: package
        ├───rust-hello-s390x-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-s390x-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-wasm32-unknown-unknown: package
        ├───rust-hello-wasm32-unknown-unknown-deps: package
        ├───rust-hello-wasm32-unknown-unknown-oci: package
        ├───rust-hello-wasm32-unknown-unknown-oci-dir: package
        ├───rust-hello-wasm32-unknown-unknown-oci-manifest: package
        ├───rust-hello-wasm32-wasip2: package
        ├───rust-hello-wasm32-wasip2-deps: package
        ├───rust-hello-wasm32-wasip2-oci: package
        ├───rust-hello-wasm32-wasip2-oci-dir: package
        ├───rust-hello-wasm32-wasip2-oci-manifest: package
        ├───rust-hello-x86_64-apple-darwin: package
        ├───rust-hello-x86_64-apple-darwin-deps: package
        ├───rust-hello-x86_64-apple-darwin-oci: package
        ├───rust-hello-x86_64-apple-darwin-oci-dir: package
        ├───rust-hello-x86_64-apple-darwin-oci-manifest: package
        ├───rust-hello-x86_64-pc-windows-gnu: package
        ├───rust-hello-x86_64-pc-windows-gnu-deps: package
        ├───rust-hello-x86_64-pc-windows-gnu-oci: package
        ├───rust-hello-x86_64-pc-windows-gnu-oci-dir: package
        ├───rust-hello-x86_64-pc-windows-gnu-oci-manifest: package
        ├───rust-hello-x86_64-unknown-linux-gnu: package
        ├───rust-hello-x86_64-unknown-linux-gnu-deps: package
        ├───rust-hello-x86_64-unknown-linux-gnu-oci: package
        ├───rust-hello-x86_64-unknown-linux-gnu-oci-dir: package
        ├───rust-hello-x86_64-unknown-linux-gnu-oci-manifest: package
        ├───rust-hello-x86_64-unknown-linux-musl: package
        ├───rust-hello-x86_64-unknown-linux-musl-deps: package
        ├───rust-hello-x86_64-unknown-linux-musl-oci: package
        ├───rust-hello-x86_64-unknown-linux-musl-oci-dir: package
        └───rust-hello-x86_64-unknown-linux-musl-oci-manifest: package
```

</details>

# Motivation

For a brief overview of motivation of this project to exist, see this talk at FOSDEM'23: https://archive.fosdem.org/2023/schedule/event/nix_and_nixos_a_success_story/
