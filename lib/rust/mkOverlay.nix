{
  self,
  crane,
  flake-utils,
  nixlib,
  nixpkgs,
  rust-overlay,
  ...
}:
with self.lib.rust;
  args: final: pkgs:
    mkPackages (args
      // {
        inherit
          pkgs
          ;
      })
