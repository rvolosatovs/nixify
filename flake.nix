{
  description = "Simple, yet extensible nix flake bootstrapping library for real-world projects";

  inputs.crane.inputs.flake-utils.follows = "flake-utils";
  inputs.crane.inputs.nixpkgs.follows = "nixpkgs";
  inputs.crane.inputs.rust-overlay.follows = "rust-overlay";
  inputs.crane.url = github:rvolosatovs/crane/feat/wit;
  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.nix-filter.url = github:numtide/nix-filter;
  inputs.nixlib.url = github:nix-community/nixpkgs.lib;
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixpkgs-22.11-darwin;
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
