{
  self,
  nixlib,
  ...
}:
with nixlib.lib;
with builtins;
  {
    buildInputs ? [],
    nativeBuildInputs ? [],
  }:
    mapAttrs (n: v:
      v.overrideAttrs (attrs: {
        buildInputs = attrs.buildInputs ++ buildInputs;

        nativeBuildInputs = attrs.nativeBuildInputs ++ nativeBuildInputs;
      }))
