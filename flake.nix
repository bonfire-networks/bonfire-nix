{
  description = "A simple NixOS flake for Bonfire";

  inputs = {
    # NixOS official package source, using the nixos-25.05 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Nixos module, consumed by other flakes
    nixosModules."bonfire" = { config }: { options = {}; config = {}; };
    # Default module
    nixosModules.default = "bonfire";
   };
}
