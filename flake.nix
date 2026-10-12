{
  description = "NixOs and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          ./hosts/nixos/system/configuration.nix
        ];
      };

      homeConfigurations."hwata@nixos" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./hosts/nixos/home/home.nix
          ];
        };
    };
}
