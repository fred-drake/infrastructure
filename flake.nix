{
  description = "Ansible environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6a9beaf893707ea2ce653dc2bacad484f084b5ad";
    flake-utils.url = "github:numtide/flake-utils";

    # Home Manager for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python312
            git
            ansible
            ansible-lint
            kubectl
            kubeseal
            yq-go
            bws
            just
          ];

          shellHook = ''
            echo "-----------------------------------------------"
            echo "Welcome to the Ansible development environment!"
            echo "-----------------------------------------------"
          '';
        };
      }
    );
}
