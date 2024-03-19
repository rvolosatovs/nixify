{
  self,
  nixlib,
  nix-log,
  ...
}:
with nixlib.lib;
with nixlib.lib.path.subpath;
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

      # normalise with `..` support, unlike the nixpkgs one
      normalise' = p:
        if hasPrefix "/" p
        then throw "absolute paths not supported"
        else let
          merged = concatStringsSep "/" (
            # Reverse the source components and fold from the right to simplify merge
            reverseList (
              foldr (
                c: p:
                  if c == ".."
                  then tail p
                  else if c == "." || c == ""
                  then p
                  else [c] ++ p
              )
              (reverseList (splitString "/" src)) (splitString "/" p)
            )
          );
        in
          removePrefix "." (normalise (removePrefix "/" merged));

      collectPathDeps = attrs: let
        depAttrs =
          filterAttrs (k: _: k == "build-dependencies" || k == "dependencies" || k == "dev-dependencies")
          attrs;
        deps = collect (dep: dep ? path && normalise' dep.path != src) depAttrs;
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
          // listToAttrs (map (
              {
                name,
                path ? null,
                ...
              }:
                if path != null
                then nameValuePair path name
                else if autobins && pathExists "${src}/src/main.rs" && name == cargoToml.package.name
                then nameValuePair "src/main.rs" name
                else if autobins && pathExists "${src}/src/bin/${name}.rs"
                then nameValuePair "src/bin/${name}.rs" name
                else if autobins && pathExists "${src}/src/bin/${name}/main.rs"
                then nameValuePair "src/bin/${name}/main.rs" name
                else throw "failed to determine `${name}` binary path, please file a bug report and explicitly set `path` in `Cargo.toml` to temporarily work around this issue"
            )
            bin)
        )
      )
      ++ optionals (build'.workspace || !isPackage || packagesSelected) (flatten (map f workspace));
  in
    if build ? bins && length build.bins > 0
    then build.bins
    else unique (f src)
