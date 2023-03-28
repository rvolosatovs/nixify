{self, ...}:
with self.lib.rust;
  args: pkgs: let
    attrs = mkAttrs args pkgs;
  in
    if attrs ? packages
    then attrs.packages
    else throw "no packages generated for library crate (set `build.workspace = true` if there are binary subcrates in the workspace)"
