{
  self,
  nixlib,
  ...
}:
with builtins;
with nixlib.lib;
with self.lib.rust;
  {
    build ? defaultBuildConfig,
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    doc ? defaultDocConfig,
    doCheck ? true,
    pkgsFor ? defaultPkgsFor,
    pname ? null,
    rustupToolchain ? defaultRustupToolchain,
    src,
    targets ? null,
    test ? defaultTestConfig,
    version ? null,
    withToolchain ? defaultWithToolchain,
  } @ args: final: let
    attrs = mkAttrs args final;
  in
    if attrs ? overlay
    then attrs.overlay
    else const {}
