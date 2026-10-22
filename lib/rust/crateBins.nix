{
  self,
  nixlib,
  nix-log,
  ...
}:
with nixlib.lib;
with builtins;
with nix-log.lib;
with self.lib;
with self.lib.rust;
{
  build ? defaultBuildConfig,
  src,
}:
let
  build' = defaultBuildConfig // build;
  packagesSelected = length build'.packages > 0;
  readCargoToml = src: readTOMLOr "${src}/Cargo.toml" { };

  canonicalise =
    p:
    "/"
    + concatStringsSep "/" (
      foldl' (
        acc: c:
        if c == "" || c == "." then
          acc
        else if c == ".." then
          optionals (acc != [ ]) (init acc)
        else
          acc ++ [ c ]
      ) [ ] (splitString "/" p)
    );

  unglob =
    prefix: parts:
    if parts == [ ] then
      [ prefix ]
    else
      let
        h = head parts;
        t = tail parts;
        regex = "^${concatMapStringsSep ".*" escapeRegex (splitString "*" h)}$";
      in
      if hasInfix "*" h then
        concatMap (name: unglob "${prefix}/${name}" t) (
          optionals (pathIsDirectory prefix) (
            filter (name: match regex name != null && pathIsDirectory "${prefix}/${name}") (
              attrNames (readDir prefix)
            )
          )
        )
      else
        unglob "${prefix}/${h}" t;

  root = canonicalise "${src}";
  rootCargoToml = readCargoToml root;
  workspace = rootCargoToml.workspace or { };

  absolute = dir: p: canonicalise (if hasPrefix "/" p then p else "${dir}/${p}");
  isUnder = prefix: dir: dir == prefix || hasPrefix "${prefix}/" dir;

  expand =
    globs:
    map canonicalise (
      concatMap (glob: unglob (optionalString (!(hasPrefix "/" glob)) root) (splitString "/" glob)) globs
    );

  isExcluded =
    dir:
    !any (member: isUnder (absolute root member) dir) workspace.members or [ ]
    && any (exclude: isUnder (absolute root exclude) dir) workspace.exclude or [ ];

  depPaths =
    dir: deps:
    concatLists (
      mapAttrsToList (
        name: dep:
        if dep.workspace or false then
          depPaths root { ${name} = workspace.dependencies.${name} or { }; }
        else
          optional (isAttrs dep && dep ? path) (absolute dir dep.path)
      ) deps
    );

  pathDeps =
    dir: cargoToml:
    trace' "pathDeps" { inherit dir; } concatMap (
      attrs:
      concatMap (kind: depPaths dir attrs.${kind} or { }) [
        "build-dependencies"
        "dependencies"
        "dev-dependencies"
      ]
    ) ([ cargoToml ] ++ attrValues cargoToml.target or { });

  isMember = dir: isUnder root dir && !isExcluded dir;
  defaultMembers = expand workspace.default-members;

  follow =
    if packagesSelected && !build'.workspace then
      isUnder root
    else
      dir: rootCargoToml ? workspace && isMember dir;

  rootCrate = {
    key = root;
    cargoToml = rootCargoToml;
  };

  rootOnly =
    rootCargoToml ? package && !build'.workspace && !packagesSelected && !(workspace ? default-members);

  crates =
    if rootOnly then
      [ rootCrate ]
    else
      genericClosure {
        startSet = [
          rootCrate
        ]
        ++ map (key: {
          inherit key;
          cargoToml = readCargoToml key;
        }) (filter isMember (expand workspace.members or [ ]));
        operator =
          { key, cargoToml }:
          map (dir: {
            key = dir;
            cargoToml = readCargoToml dir;
          }) (filter follow (pathDeps key cargoToml));
      };

  includeCrate =
    { key, cargoToml }:
    cargoToml ? package
    && (
      if build'.workspace then
        !elem cargoToml.package.name build'.excludes
      else if packagesSelected then
        elem cargoToml.package.name build'.packages
      else if workspace ? default-members then
        elem key defaultMembers
      else
        !(rootCargoToml ? package) || key == root
    );

  crateBins' =
    { key, cargoToml }:
    let
      name = cargoToml.package.name;
      withDeps = concatMap (
        f: [ f ] ++ optional (match "[^/?]+/.+" f != null) (head (splitString "/" f))
      );
      features = catAttrs "key" (genericClosure {
        startSet = map (key: { inherit key; }) (
          withDeps (
            map (removePrefix "${name}/") build'.features ++ optional (!build'.noDefaultFeatures) "default"
          )
        );
        operator = { key }: map (key: { inherit key; }) (withDeps cargoToml.features.${key} or [ ]);
      });
      enabled = bin: build'.allFeatures || all (f: elem f features) (bin.required-features or [ ]);

      explicit = filter (bin: bin ? name) cargoToml.bin or [ ];
      explicitNames = catAttrs "name" explicit;
      explicitPaths = map (removePrefix "./") (catAttrs "path" explicit);

      binDir = "${key}/src/bin";
      isBinFile = file: type: type != "directory" && hasSuffix ".rs" file;
      auto =
        optional (pathExists "${key}/src/main.rs") {
          inherit name;
          path = "src/main.rs";
        }
        ++ optionals (pathIsDirectory binDir) (
          mapAttrsToList
            (file: type: {
              name = removeSuffix ".rs" file;
              path = if isBinFile file type then "src/bin/${file}" else "src/bin/${file}/main.rs";
            })
            (
              filterAttrs (
                file: type: isBinFile file type || type != "regular" && pathExists "${binDir}/${file}/main.rs"
              ) (readDir binDir)
            )
        );
      edition =
        if cargoToml.package.edition.workspace or false then
          rootCargoToml.workspace.package.edition or "2015"
        else
          cargoToml.package.edition or "2015";
      auto' = optionals (cargoToml.package.autobins or (edition != "2015" || !(cargoToml ? bin))) (
        filter (bin: !elem bin.name explicitNames && !elem bin.path explicitPaths) auto
      );
    in
    trace' "crateBins" {
      inherit
        auto'
        cargoToml
        explicit
        features
        key
        ;
    } catAttrs "name" (auto' ++ filter enabled explicit);
in
if build'.bins != [ ] then
  build'.bins
else
  unique (concatMap crateBins' (filter includeCrate crates))
