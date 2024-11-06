{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
			manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          toolchain
          # We want the unwrapped version, "rust-analyzer" (wrapped) comes with nixpkgs' toolchain
          pkgs.rust-analyzer-unwrapped
        ];
        RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
      };
			# for this to pick up the correct toolchain, it requires `flake.lock` to be commited
      packages.${system}.default = pkgs.rustPlatform.buildRustPackage rec {
        pname = manifest.name;
        version = manifest.version;

        cargoLock.lockFile = ./Cargo.lock;
        src = pkgs.lib.cleanSource ./.;
				nativeBuildInputs = [ toolchain ];
      };
    };
}
