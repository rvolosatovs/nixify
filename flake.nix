{
  nixConfig.extra-substituters = [
    "https://nixify.cachix.org"
    "https://crane.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.garnix.io"
  ];
  nixConfig.extra-trusted-public-keys = [
    "nixify.cachix.org-1:95SiUQuf8Ij0hwDweALJsLtnMyv/otZamWNRp1Q1pXw="
    "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  ];

  description = "Simple, yet extensible nix flake bootstrapping library for real-world projects";

  inputs.advisory-db.flake = false;
  inputs.advisory-db.url = "github:rustsec/advisory-db";
  inputs.crane.url = "github:ipetkov/crane/v0.15.0";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.macos-sdk.url = "https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz";
  inputs.macos-sdk.flake = false;
  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.nix-log.url = "github:rvolosatovs/nix-log";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  inputs.nixpkgs-jshon.url = "github:nixos/nixpkgs/89023fc074c2333ec5f1d28075602c94341655d2"; # https://github.com/NixOS/nixpkgs/pull/272259
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.rust-overlay.inputs.flake-utils.follows = "flake-utils";
  inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  outputs = inputs: let
    lib = import ./lib inputs;
  in
    with lib;
      mkFlake {
        excludePaths = [
          ".github"
          ".gitignore"
          "flake.lock"
          "flake.nix"
          "LICENSE"
          "README.md"
        ];

        withDevShells = {
          pkgs,
          devShells,
          ...
        }:
          extendDerivations {
            buildInputs = with pkgs; [
              buildah
              wasmtime
              zig
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
