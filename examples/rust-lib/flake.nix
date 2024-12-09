{
  inputs.nixify.url = "github:rvolosatovs/nixify";

  outputs =
    { nixify, ... }:
    nixify.lib.rust.mkFlake {
      src = ./.;
      cargoLock = ./Cargo.test.lock;
    };
}
