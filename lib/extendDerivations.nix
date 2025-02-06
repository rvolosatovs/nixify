{
  self,
  nixlib,
  ...
}:
with nixlib.lib;
with builtins;
{
  buildInputs ? [ ],
  depsBuildBuild ? [ ],
  env ? null,
  nativeBuildInputs ? [ ],
}:
mapAttrs (
  n: v:
  v.overrideAttrs (
    attrs:
    {
      buildInputs = (attrs.buildInputs or [ ]) ++ buildInputs;
      depsBuildBuild = (attrs.depsBuildBuild or [ ]) ++ depsBuildBuild;
      nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ nativeBuildInputs;
    }
    // optionalAttrs (env != null) {
      env = (attrs.env or { }) // env;
    }
  )
)
