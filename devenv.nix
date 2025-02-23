{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/basics/
  env.GREET = "devenv";

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
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
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
