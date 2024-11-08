{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs = {nixify, ...}:
    nixify.lib.rust.mkFlake {
      src = ./.;

      excludePaths = [
        "rust-toolchain.toml"
      ];

      build.workspace = true;
      clippy.workspace = true;
      test.allTargets = true;
      test.workspace = true;

      buildOverrides = {
        pkgs,
        pkgsCross ? pkgs,
        ...
      }: {
        buildInputs ? [],
        depsBuildBuild ? [],
        ...
      }:
        with pkgs.lib; {
          buildInputs =
            buildInputs
            ++ optional pkgs.stdenv.hostPlatform.isDarwin pkgs.libiconv;

          depsBuildBuild =
            depsBuildBuild
            ++ optional pkgsCross.stdenv.hostPlatform.isDarwin pkgsCross.xcbuild.xcrun;
        };
    };
}
