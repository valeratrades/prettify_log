{ pkgs }:

let
  rust-overlay = builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
  pkgsWithOverlay = import pkgs.path {
    overlays = [(import rust-overlay)];
    inherit (pkgs) system;
  };
  toolchain = pkgsWithOverlay.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
in
  pkgs.mkShell {
    packages = [
      toolchain
    ];
  }

