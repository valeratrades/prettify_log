{
  description = "A flake for your Rust project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = nixpkgs.legacyPackages;
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = pkgsFor.${system};
        overrides = builtins.fromTOML (builtins.readFile ./.cargo/rust-toolchain.toml);
        manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
        libPath = pkgs.lib.makeLibraryPath [
          # add any external libraries needed for the Rust project here
        ];
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            clang
            llvmPackages.bintools
            rustup
          ];

          shellHook = ''
            export PATH=$PATH:''${CARGO_HOME:-~/.cargo}/bin
            export PATH=$PATH:''${RUSTUP_HOME:-~/.rustup}/toolchains/${overrides.toolchain.channel}-x86_64-unknown-linux-gnu/bin/
          '';

          RUSTC_VERSION = overrides.toolchain.channel;
          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
          RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') [
            # add libraries here (e.g., pkgs.libvmi)
          ]);
          LD_LIBRARY_PATH = libPath;
          BINDGEN_EXTRA_CLANG_ARGS = 
            (builtins.map (a: ''-I"${a}/include"'') [
              # add dev libraries here (e.g., pkgs.libvmi.dev)
              pkgs.glibc.dev
            ])
            ++ [
              ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
              ''-I"${pkgs.glib.dev}/include/glib-2.0"''
              ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
            ];
        };

        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = manifest.name;
          version = manifest.version;

          src = pkgs.lib.cleanSource ./.;
          cargoLock.lockFile = ./Cargo.lock;

          buildInputs = with pkgs; [
            clang
            llvmPackages.bintools
            rustup
          ];
          nativeBuildInputs = with pkgs; [ pkg-config ];

          RUSTC_VERSION = overrides.toolchain.channel;
          LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
          RUSTFLAGS = (builtins.map (a: ''-L ${a}/lib'') [
            # add libraries here (e.g., pkgs.libvmi)
          ]);
          LD_LIBRARY_PATH = libPath;
          BINDGEN_EXTRA_CLANG_ARGS = 
            (builtins.map (a: ''-I"${a}/include"'') [
              # add dev libraries here (e.g., pkgs.libvmi.dev)
              pkgs.glibc.dev
            ])
            ++ [
              ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
              ''-I"${pkgs.glib.dev}/include/glib-2.0"''
              ''-I${pkgs.glib.out}/lib/glib-2.0/include/''
            ];
        };
      });
}

