{
  self,
  nixlib,
  ...
}:
with nixlib.lib;
with builtins;
  {
    buildInputs ? [],
    inputsFrom ? [],
    nativeBuildInputs ? [],
    packages ? [],
  }:
    mapAttrs (n: v:
      v.overrideAttrs (attrs: {
        buildInputs = (attrs.buildInputs or []) ++ buildInputs;
        inputsFrom = (attrs.inputsFrom or []) ++ inputsFrom;
        nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ nativeBuildInputs;
        packages = (attrs.packages or []) ++ packages;
      }))
