{
  self,
  flake-utils,
  nixlib,
  ...
}:
with flake-utils.lib.system;
with nixlib.lib;
with self.lib;
let
  assertRustOutputs =
    flake: name:
    assert name != "default";
    assert name != "rust";
    assert flake ? checks;
    assert flake ? devShells;
    assert flake ? overlays;
    assert flake ? packages;
    assert flake.overlays ? "${name}";
    assert flake.overlays ? default;
    assert flake.overlays ? fenix;
    assert flake.overlays ? rust-overlay;
    system:
    assert flake.checks.${system} ? clippy;
    assert flake.checks.${system} ? fmt;
    assert flake.checks.${system} ? nextest;
    assert flake.devShells.${system} ? default;
    mapAttrs' (n: nameValuePair "${name}-check-${n}") flake.checks.${system}
    // mapAttrs' (n: nameValuePair "${name}-shell-${n}") flake.devShells.${system}
    // mapAttrs' (n: nameValuePair "${name}-package-${n}") flake.packages.${system};

  flakes.rust.complex = (import ../examples/rust-complex/flake.nix).outputs {
    self = ../examples/rust-complex;
    nixify = self;
  };

  flakes.rust.hello = (import ../examples/rust-hello/flake.nix).outputs {
    self = ../examples/rust-hello;
    nixify = self;
  };

  flakes.rust.hello-multibin = (import ../examples/rust-hello-multibin/flake.nix).outputs {
    self = ../examples/rust-hello-multibin;
    nixify = self;
  };

  flakes.rust.lib = (import ../examples/rust-lib/flake.nix).outputs {
    self = ../examples/rust-lib;
    nixify = self;
  };

  flakes.rust.workspace = (import ../examples/rust-workspace/flake.nix).outputs {
    self = ../examples/rust-workspace;
    nixify = self;
  };
in
genAttrs [ aarch64-darwin aarch64-linux x86_64-darwin x86_64-linux ] (
  system:
  assert flakes.rust.complex.checks.${system} ? doctest;
  assert flakes.rust.complex.packages.${system} ? default;
  assert flakes.rust.hello-multibin.packages.${system} ? default;
  assert flakes.rust.hello.packages.${system} ? default;
  assert flakes.rust.workspace.packages.${system} ? default;
  foldl (
    checks: example: checks // (assertRustOutputs flakes.rust.${example} "rust-${example}" system)
  ) { } (attrNames flakes.rust)
)
