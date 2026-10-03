#/bin/bash

nix build '.#homeConfigurations."hwata@nixos".activationPackage'
home-manager switch --flake '.#hwata@nixos'
