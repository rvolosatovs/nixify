{
  self,
  nixlib,
  ...
}:
with nixlib.lib;
with builtins;
  {
    buildInputs ? [],
    depsBuildBuild ? [],
    env ? null,
    inputsFrom ? [],
    nativeBuildInputs ? [],
    packages ? [],
  }:
    mapAttrs (n: v:
      v.overrideAttrs (attrs:
        {
          buildInputs = (attrs.buildInputs or []) ++ buildInputs;
          depsBuildBuild = (attrs.depsBuildBuild or []) ++ depsBuildBuild;
          inputsFrom = (attrs.inputsFrom or []) ++ inputsFrom;
          nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ nativeBuildInputs;
          packages = (attrs.packages or []) ++ packages;
        }
        // optionalAttrs (env != null) {
          env = (attrs.env or {}) // env;
        }))
