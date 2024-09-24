{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-generators, ... }:
    let
      # pkgsForSystem = system: import nixpkgs { };
      # allVMs = [ "x86_64-linux" "aarch64-linux" ];
      # forAllVMs = f: nixpkgs.lib.genAttrs allVMs (system: f {
      #   inherit system;
      #   pkgs = pkgsForSystem system;
      # });
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # packages = forAllVMs ({ system, pkgs }: {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
        qcow = nixos-generators.nixosGenerate {
          system = system;
          specialArgs = {
            pkgs = pkgs;
            diskSize = 64 * 1024;
          };
          modules = [
            ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
            ./configuration.nix
            ({ ... }: {
              system.stateVersion = "24.05";
            })
          ];
          format = "qcow";
        };
        }
      );

    };
}
