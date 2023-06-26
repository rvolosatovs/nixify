{
  nixConfig.extra-substituters = [
    "https://nix-community.cachix.org"
    "https://cache.garnix.io"
  ];
  nixConfig.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  ];

  description = "Simple, yet extensible nix flake bootstrapping library for real-world projects";

  inputs.advisory-db.flake = false;
  inputs.advisory-db.url = github:rustsec/advisory-db;
  inputs.crane.inputs.flake-utils.follows = "flake-utils";
  inputs.crane.inputs.nixpkgs.follows = "nixpkgs";
  inputs.crane.inputs.rust-overlay.follows = "rust-overlay";
  inputs.crane.url = github:ipetkov/crane;
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.fenix.url = github:nix-community/fenix;    
  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.nix-filter.url = github:numtide/nix-filter;
  inputs.nix-log.url = github:rvolosatovs/nix-log;
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
