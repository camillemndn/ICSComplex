let
  inputs = import ./deps;
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (_: prev: {
        rPackages = prev.rPackages.override {
          overrides = with prev.rPackages; {
            dda = buildRPackage {
              name = "dda";
              src = pkgs.fetchFromGitHub {
                owner = "camillemndn";
                repo = "dda";
                rev = "v0.0.0.9016";
                hash = "sha256-sHaRvP9rCPW7DO7zvFYkQNZpePplacGOYrTpFibm6Lw=";
              };
              propagatedBuildInputs = [
                fda
                GGally
                ggplot2
                ICS
                ICSOutlier
                memoise
              ];
            };

            tidyfun = buildRPackage {
              name = "tidyfun";
              src = pkgs.fetchFromGitHub {
                owner = "tidyfun";
                repo = "tidyfun";
                rev = "d9c4adbd2ff1179cc1f37cb34464e42f5fe2739a";
                hash = "sha256-uSpwjZZ2+GZZpNn5PFwHfRal7o5MTd5rST8jKd6Kpdo=";
              };
              propagatedBuildInputs = [
                tf
                dplyr
                GGally
                ggplot2
                pillar
                purrr
                tibble
                tidyr
                tidyselect
              ];
            };
          };
        };
      })
    ];
  };

  r-deps = with pkgs.rPackages; [
    dda
    DeBoinR
    fdaoutlier
    sf
    tf
    tidyfun
    tidyverse

    devtools
    languageserver
    quarto
  ];

  pre-commit-hook = (import inputs.git-hooks).run {
    src = ./.;

    hooks = {
      statix.enable = true;
      deadnix.enable = true;
      rfc101 = {
        enable = true;
        name = "RFC-101 formatting";
        entry = "${pkgs.lib.getExe pkgs.nixfmt-rfc-style}";
        files = "\\.nix$";
      };
      commitizen.enable = true;
    };
  };
in

rec {
  devShells.default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      npins
      (quarto.override { extraRPackages = r-deps; })
      (rstudioWrapper.override { packages = r-deps; })
      (rWrapper.override { packages = r-deps; })
      texliveFull
      librsvg
    ];
    shellHook = ''
      ${pre-commit-hook.shellHook}
    '';
  };

  packages.x86_64-linux = {
    website = pkgs.callPackage (
      {
        stdenv,
        image_optim,
        quarto,
        texliveFull,
        ...
      }:

      stdenv.mkDerivation {
        name = "camillemondon-icscomplex";
        src = builtins.fetchGit ./.;

        buildInputs = [
          image_optim
          (quarto.override { extraRPackages = r-deps; })
          texliveFull
        ];

        HOME = ".";

        buildPhase = ''
          quarto render
          image_optim --recursive _book
        '';

        installPhase = ''
          cp -r _book $out
        '';
      }
    ) { };
  };

  checks.default = {
    inherit packages;
  };
}
