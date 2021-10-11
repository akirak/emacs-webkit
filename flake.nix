{
  description = "An Emacs Dynamic Module for WebKit, aka a fully fledged browser inside emacs";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

  outputs = { self, nixpkgs, emacs-overlay, flake-utils, pre-commit-hooks }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs =
          import nixpkgs {
            inherit system;
            overlays = [ emacs-overlay.overlay ];
          }
        ;
        emacs-webkit = import ./default.nix {
          inherit pkgs;
          packageSrc = self;
        };
      in
      rec {
        packages = flake-utils.lib.flattenTree {
          inherit emacs-webkit;
          emacs = (pkgs.emacsPackagesFor pkgs.emacsPgtk).emacsWithPackages (
            epkgs: with epkgs; [
              emacs-webkit
            ]
          );
        };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = builtins.path {
              path = ./.;
              name = "emacs-webkit-src";
            };
            hooks = {
              nixpkgs-fmt.enable = true;
              nix-linter.enable = true;
            };
          };
        };
        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };
      }
    );

}
