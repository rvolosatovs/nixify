{
  self,
  nixlib,
  ...
}:
with builtins;
with nixlib.lib;
with self.lib.rust;
  args: final: let
    attrs = mkAttrs args final;
  in
    attrs.overlay
