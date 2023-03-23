{
  flake-utils,
  nixlib,
  nixpkgs,
  nix-filter,
  ...
} @ inputs:
with flake-utils.lib.system;
with nixlib.lib;
with builtins; let
  NIXIFY_LOG = let
    env = getEnv "NIXIFY_LOG";
  in
    if env == ""
    then "warn"
    else env;

  logLevel.isError = NIXIFY_LOG == "error";
  logLevel.isWarn = NIXIFY_LOG == "warn";
  logLevel.isInfo = NIXIFY_LOG == "info";
  logLevel.isDebug = NIXIFY_LOG == "debug";
  logLevel.isTrace =
    (NIXIFY_LOG != "")
    && (!logLevel.isError)
    && (!logLevel.isWarn)
    && (!logLevel.isInfo)
    && (!logLevel.isDebug);

  trace = msg:
    with logLevel;
      if isTrace
      then builtins.trace "TRACE: ${msg}"
      else x: x;

  debug = msg:
    with logLevel;
      if isDebug || isTrace
      then builtins.trace "DEBUG: ${msg}"
      else x: x;

  info = msg:
    with logLevel;
      if isInfo || isDebug || isTrace
      # info already adds a prefix
      then nixlib.lib.info msg
      else x: x;

  warn = msg:
    with logLevel;
      if isWarn || isInfo || isDebug || isTrace
      # warn already adds a prefix and has additional functionality built-in
      then nixlib.lib.warn msg
      else x: x;

  mkAttrLog = log: msg: attrs:
    log "${msg} ${(toJSON attrs)}";

  f = self': {
    inherit
      trace
      debug
      info
      warn
      ;

    warnIf = cond: msg:
      if cond
      then warn msg
      else x: x;

    trace' = mkAttrLog trace;
    debug' = mkAttrLog debug;
    info' = mkAttrLog info;
    warn' = mkAttrLog warn;

    eq = x: y: x == y;

    rust = import ./rust inputs;

    mkFlake = import ./mkFlake.nix inputs self';

    extendDerivations = import ./extendDerivations.nix inputs;

    filterSource = {
      include ? null,
      exclude ? self'.defaultExcludePaths,
      src,
    }:
      nix-filter.lib.filter ({
          inherit exclude;
          root = src;
        }
        // optionalAttrs (include != null) {
          inherit include;
        });

    readTOML = file: fromTOML (readFile file);
    readTOMLOr = path: def:
      if pathExists path
      then self'.readTOML path
      else def;

    defaultExcludePaths = [
      ".codecov.yml"
      ".github"
      ".gitignore"
      ".mailmap"
      "flake.lock"
      "flake.nix"
    ];

    defaultSystems = [
      aarch64-darwin
      aarch64-linux
      x86_64-darwin
      x86_64-linux
    ];

    defaultWithApps = {apps, ...}: apps;
    defaultWithChecks = {checks, ...}: checks;
    defaultWithDevShells = {devShells, ...}: devShells;
    defaultWithFormatter = {formatter, ...}: formatter;
    defaultWithOverlays = {overlays, ...}: overlays;
    defaultWithPackages = {packages, ...}: packages;
  };
in
  fix f
