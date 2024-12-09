{ self, ... }:
with self.lib.rust;
args: pkgs:
let
  attrs = mkAttrs args pkgs;
in
attrs.checks
