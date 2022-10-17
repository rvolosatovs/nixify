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
  {
    clippy ? defaultClippyConfig,
    pname,
    rustupToolchainFile,
    src,
    targets ? defaultRustTargets,
    test ? defaultTestConfig,
    version,
  } @ args: final: pkgs:
    mkPackages (args
      // {
        inherit
          pkgs
          ;
      })
