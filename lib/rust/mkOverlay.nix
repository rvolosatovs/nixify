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
  args: final: prev:
    mkPackages (args
      // {
        pkgs = prev;
      })
