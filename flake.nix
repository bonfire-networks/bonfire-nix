{
  description = "A simple NixOS flake for Hetzner Cloud server with Bonfire";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    bonfire-app.url = "github:bonfire-networks/bonfire-app/main";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, bonfire-app, flake-utils, sops-nix, disko, ... }@inputs: {
    nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
      ];
      specialArgs = {
        inherit bonfire-app;
      };
    };
  };
}