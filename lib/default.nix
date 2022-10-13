inputs: {
  mkFlake = import ./mkFlake.nix inputs;

  rust = import ./rust inputs;
}
