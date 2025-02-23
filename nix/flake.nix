{
  description = "Manage NixOS server remotely";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    disko,
    ...
  }: {
    nixosConfigurations.forgejo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./configuration.nix
      ];
    };
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      defaults = {pkgs, ...}: {
        environment.systemPackages = [
          pkgs.curl
        ];
      };
      forgejo = {pkgs, ...}: {
        deployment = {
          targetHost = "forgejo";
          targetPort = 22;
          targetUser = "fdrake";
          buildOnTarget = true;
          tags = ["homelab"];
        };
        nixpkgs.system = "x86_64-linux";
        imports = [
          disko.nixosModules.disko
          ./configuration.nix
        ];
        time.timeZone = "America/New_York";
      };
    };
  };
}
