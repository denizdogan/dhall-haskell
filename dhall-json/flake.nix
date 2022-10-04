{
  description = "A very basic flake";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix/master";
  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils, haskellNix }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
    let
      overlays = [ haskellNix.overlay
        (final: prev: {
          # This overlay adds our project to pkgs
          dhall-json =
            final.haskell-nix.project' {
              src = ./.;
              compiler-nix-name = "ghc8107";
              # This is used by `nix develop .` to open a shell for use with
              # `cabal`, `hlint` and `haskell-language-server`
              shell.tools = {
                cabal = {};
                hlint = {
                  version = "3.4.1";
                  };
                haskell-language-server = {};
              };
              # Non-Haskell shell tools go here
              shell.buildInputs = with pkgs; [
                nixpkgs-fmt
                rnix-lsp
              ];
              # This adds `js-unknown-ghcjs-cabal` to the shell.
              # shell.crossPlatforms = p: [p.ghcjs];
            };
        })
      ];
      pkgs = import nixpkgs { inherit system overlays; inherit (haskellNix) config; };
      flake = pkgs.dhall-json.flake {
        # This adds support for `nix build .#js-unknown-ghcjs:dhall-json:lib:dhall-json`
        # crossPlatforms = p: [p.ghcjs];
      };
    in flake // {
      # Built by `nix build .`
      packages.default = flake.packages."dhall-json:lib:dhall-json";
      packages.dhall-json = flake.packages."dhall-json:lib:dhall-json";
      packages.dhall-to-json = flake.packages."dhall-json:exe:dhall-to-json";
      packages.dhall-to-yaml = flake.packages."dhall-json:exe:dhall-to-yaml";
      packages.json-to-dhall = flake.packages."dhall-json:exe:json-to-dhall";
    });
}
