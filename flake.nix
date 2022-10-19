{
  description = "Simple, yet extensible nix flake bootstrapping library for real-world projects";

  inputs.crane.inputs.flake-utils.follows = "flake-utils";
  inputs.crane.inputs.nixpkgs.follows = "nixpkgs";
  inputs.crane.inputs.rust-overlay.follows = "rust-overlay";
  inputs.crane.url = github:ipetkov/crane;
  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.nixlib.url = github:nix-community/nixpkgs.lib;
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixpkgs-22.05-darwin;
  inputs.rust-overlay.inputs.flake-utils.follows = "flake-utils";
  inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  inputs.rust-overlay.url = github:oxalica/rust-overlay;

  outputs = inputs: let
    lib = import ./lib inputs;
  in
    with lib;
      mkFlake {
        withDevShells = {
          pkgs,
          devShells,
          ...
        }:
          extendDerivations {
            buildInputs = with pkgs; [
              wasmtime
            ];
          }
          devShells;
      }
      // {
        inherit lib;

        checks = import ./checks inputs;
        templates = import ./templates inputs;
      };
}
