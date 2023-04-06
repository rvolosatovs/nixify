{
  self,
  nixlib,
  nix-log,
  ...
}:
with nixlib.lib;
with nixlib.lib.path;
with builtins;
with nix-log.lib;
with self.lib;
with self.lib.rust;
  {
    build ? defaultBuildConfig,
    src,
  }: let
    build' = defaultBuildConfig // build;
    packagesSelected = length build'.packages > 0;
    readCargoToml = src: readTOMLOr "${src}/Cargo.toml" {};

    f = src: let
      cargoToml = readCargoToml src;

      isPackage = cargoToml ? package;

      includeCrate =
        if build'.workspace || !isPackage
        then true
        else if packagesSelected
        then any (p: p == cargoToml.package.name) build'.packages
        else true;

      autobins = isPackage && cargoToml.package.autobins or true;
      bin = optionals isPackage cargoToml.bin or [];

      unglob' = prefix: parts:
        if parts == []
        then [prefix]
        else let
          h = head parts;
          t = tail parts;
        in
          if hasInfix "*" h
          then let
            regex = "^${replaceStrings ["*"] [".*"] h}$";
            names = filter (name: match regex name != null) (attrNames (readDir prefix));
          in
            map (h': unglob' "${prefix}/${h'}" t) names
          else unglob' "${prefix}/${h}" t;

      unglob = glob: let
        prefix = optionalString (!(hasPrefix "/" glob)) src;
        parts = splitString "/" glob;
      in
        optionals (glob != "") (unglob' prefix parts);
      workspaceMembers = cargoToml.workspace.members or [];
      workspaceMembers' = flatten (map unglob workspaceMembers);

      collectPathDeps = attrs: let
        depAttrs =
          filterAttrs (k: _: k == "build-dependencies" || k == "dependencies" || k == "dev-dependencies")
          attrs;
        deps = collect (dep: dep ? path && subpath.normalise dep.path != "./.") depAttrs;
      in
        trace' "collectPathDeps" {
          inherit
            depAttrs
            deps
            ;
        }
        map ({path, ...}:
          if hasPrefix "/" path
          then path
          else "${src}/${path}")
        deps;

      pathDeps =
        collectPathDeps cargoToml
        ++ optionals (cargoToml ? target) (flatten (attrValues (mapAttrs (_: v: collectPathDeps v) cargoToml.target)))
        ++ optionals (cargoToml ? workspace) (collectPathDeps cargoToml.workspace);

      workspace = unique (workspaceMembers' ++ pathDeps);
    in
      trace' "crateBins" {
        inherit
          autobins
          bin
          cargoToml
          includeCrate
          isPackage
          src
          workspace
          ;
      }
      optionals
      includeCrate (
        # NOTE: `listToAttrs` seems to discard keys already present in the set
        attrValues (
          optionalAttrs (autobins && pathExists "${src}/src/main.rs") {
            "src/main.rs" = cargoToml.package.name;
          }
          // listToAttrs (optionals (autobins && pathExists "${src}/src/bin") (map (name:
            nameValuePair "src/bin/${name}" (removeSuffix ".rs" name))
          (attrNames (filterAttrs (name: type: type == "regular" && hasSuffix ".rs" name || type == "directory") (readDir "${src}/src/bin")))))
          // listToAttrs (map ({
            name,
            path,
            ...
          }:
            nameValuePair path name)
          bin)
        )
      )
      ++ optionals (build'.workspace || !isPackage || packagesSelected) (flatten (map f workspace));
  in
    unique (f src)
