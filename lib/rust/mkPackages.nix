{self, ...}:
with self.lib.rust;
  {
    build ? defaultBuildConfig,
    buildOverrides ? defaultBuildOverrides,
    cargoLock ? null,
    clippy ? defaultClippyConfig,
    doCheck ? true,
    pkgsFor ? defaultPkgsFor,
    pname ? null,
    rustupToolchain ? defaultRustupToolchain,
    src,
    targets ? null,
    test ? defaultTestConfig,
    version ? null,
    withToolchain ? defaultWithToolchain,
  } @ args: pkgs: let
    attrs = mkAttrs args pkgs;
  in
    if attrs ? packages
    then attrs.packages
    else throw "no packages generated for library crate (set `build.workspace = true` if there are binary subcrates in the workspace)"
