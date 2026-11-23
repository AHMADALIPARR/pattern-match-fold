{
  description = "Pattern Match & Fold — multi-target SIMD / GPU / formal models";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "pattern-match-fold";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            nasm
            gcc
            zig
            lean4
            gnumake
          ];

          buildPhase = ''
            # Assembly kernels
            nasm -f elf64 asm/pattern_kernel.asm -o pattern_kernel.o || true
            # Zig cubin builder (comptime only)
            zig build-exe zig/emit_cubin.zig -femit-bin=emit_cubin || true
            # Lean check (type-check only)
            lean --check lean/PatternMatchFold.lean || true
          '';

          installPhase = ''
            mkdir -p $out/bin $out/share/pattern-match-fold
            cp -r asm lean zig cuda bluespec sourcepawn host bench docs $out/share/pattern-match-fold/ || true
            [ -f emit_cubin ] && cp emit_cubin $out/bin/ || true
          '';

          meta = with pkgs.lib; {
            description = "Dual-linked AVX2 / Lean 4 / GPU pattern-match-and-fold kernels";
            license = licenses.agpl3Only;
            platforms = platforms.unix;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nasm
            gcc
            zig
            lean4
            gnumake
            cudaPackages.cudatoolkit
          ];
        };
      }
    );
}
