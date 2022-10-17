{
  self,
  nixlib,
  ...
}:
with nixlib.lib;
  {
    buildInputs ? [],
    nativeBuildInputs ? [],
  }:
    mapAttrs (n: v:
      v.overrideAttrs (attrs: {
        buildInputs = attrs.buildInputs ++ buildInputs;

        nativeBuildInputs = attrs.nativeBuildInputs ++ nativeBuildInputs;
      }))
