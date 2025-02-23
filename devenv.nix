{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/basics/

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    ansible
    colmena
    kubectl
    kubeseal
    yq-go
    bws
    just
    nixos-anywhere
    opentofu
  ];

  # https://devenv.sh/languages/
  languages.python.enable = true;
  languages.ansible.enable = true;
  languages.nix.enable = true;

  # https://devenv.sh/processes/

  # https://devenv.sh/services/

  cachix.enable = false;

  # https://devenv.sh/scripts/
  scripts.nixinit.exec = ''
    cd nix
    nixos-anywhere --flake ".#$1" --build-on-remote nixos@$1
  '';

  scripts.nixupdate.exec = ''
    cd nix
    colmena apply --on $1 --impure
  '';

  enterShell = ''
    source_env "~/.bws.env"
    source_env "~/.llm_api_keys.env"
    source_env "~/.config/aider/aider_default.env"

    export SOPS_AGE_KEY_FILE=~/.age/ansible-key.txt
    export KUBECONFIG=$(expand_path ./kubeconfig)
    export ANSIBLE_CONFIG=$(expand_path ./ansible/ansible.cfg)
    export TF_VAR_BWS_TOKEN=$BWS_ACCESS_TOKEN

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

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
