{ self, nixlib, ... }:
with nixlib.lib;
with builtins;
inputs@{
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  propagatedBuildInputs ? [ ],
  propagatedNativeBuildInputs ? [ ],

  depsBuildBuild ? [ ],
  depsBuildBuildPropagated ? [ ],
  depsBuildHost ? [ ],
  depsBuildHostPropagated ? [ ],
  depsBuildTarget ? [ ],
  depsBuildTargetPropagated ? [ ],
  depsHostHost ? [ ],
  depsHostHostPropagated ? [ ],
  depsTargetTarget ? [ ],
  depsTargetTargetPropagated ? [ ],

  checkInputs ? [ ],
  nativeCheckInputs ? [ ],
  installCheckInputs ? [ ],
  nativeInstallCheckInputs ? [ ],

  env ? null,
  shellHook ? null,
}:
let
  listInputs = removeAttrs inputs [
    "env"
    "shellHook"
  ];
in
mapAttrs (
  _: v:
  v.overrideAttrs (
    attrs:
    (mapAttrs (k: xs: (attrs.${k} or [ ]) ++ xs) listInputs)
    // optionalAttrs (env != null) { env = (attrs.env or { }) // env; }
    // optionalAttrs (shellHook != null) {
      shellHook = (attrs.shellHook or "") + shellHook;
    }
  )
)
