{
  nixConfig.extra-substituters = [
    "https://nixify.cachix.org"
    "https://rvolosatovs.cachix.org"
    "https://crane.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.garnix.io"
  ];
  nixConfig.extra-trusted-public-keys = [
    "nixify.cachix.org-1:95SiUQuf8Ij0hwDweALJsLtnMyv/otZamWNRp1Q1pXw="
    "rvolosatovs.cachix.org-1:eRYUO4OXTSmpDFWu4wX3/X08MsP01baqGKi9GsoAmQ8="
    "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  ];

  description = "Simple and extensible nix flake bootstrapping library for real-world projects";

  inputs.advisory-db.flake = false;
  inputs.advisory-db.url = "github:rustsec/advisory-db";
  inputs.crane.url = "github:ipetkov/crane/v0.21.3";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs-nixos";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.macos-sdk.url = "https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz";
  inputs.macos-sdk.flake = false;
  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.nix-log.url = "github:rvolosatovs/nix-log";
  inputs.nixlib.url = "github:nix-community/nixpkgs.lib";
  inputs.nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
  inputs.nixpkgs-nixos.url = "github:nixos/nixpkgs/nixos-25.05";
  inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs-nixos";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";

  outputs =
    inputs:
    let
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

      withDevShells =
        {
          pkgs,
          devShells,
          ...
        }:
        extendDerivations {
          buildInputs = with pkgs; [
            skopeo
            wasmtime
            zig
          ];
        } devShells;
    }
    // {
      inherit lib;

      checks = import ./checks inputs;
      templates = import ./templates inputs;
    };
}
