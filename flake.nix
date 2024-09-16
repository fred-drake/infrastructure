{
  description = "Ansible environment";

  inputs = {
    nixpkgs-bws.url = "github:NixOS/nixpkgs/6a9beaf893707ea2ce653dc2bacad484f084b5ad";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs-bws, nixpkgs-unstable, flake-utils, home-manager, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs-bws = import nixpkgs-bws {
          inherit system;
          config.allowUnfree = true;
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
            pkgs-bws.bws # BWS breaks when using bleeding edge
            just
            aider-chat
          ];

          shellHook = ''
            echo "------------------------------------------------------------"
            echo ""
            echo "Welcome to the Ansible development environment!"
            echo ""
            echo "To enable this for the first time, run the following:"
            echo " - pip install -r ansible/dev-requirements.txt"
            echo " - ansible-galaxy install -r ansible/galaxy-requirements.yml"
            echo ""
            echo "------------------------------------------------------------"
          '';
        };
      }
    );
}
