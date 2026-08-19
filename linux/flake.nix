{
  description = "Framework Desktop dotfiles";

  inputs = {
    nixpkgs-linux.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-linux";
  };

  outputs =
    { home-manager, nixpkgs-linux, ... }:
    let
      # bootstrap.sh keeps this in sync with the macOS flake.
      user = "austinb";
      system = "x86_64-linux";
      pkgs = import nixpkgs-linux {
        inherit system;
        config.allowUnfree = true;
      };
      frameworkHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit user;
          homeDirectory = "/home/${user}";
          isOmarchy = true;
        };
        modules = [ ./home.nix ];
      };
    in
    {
      homeConfigurations."framework" = frameworkHome;

      # bootstrap.sh and rebuild.sh use the CLI from this exact locked flake.
      apps.${system}."home-manager" = {
        type = "app";
        program = "${home-manager.packages.${system}.default}/bin/home-manager";
      };

      checks.${system}."framework-home" = frameworkHome.activationPackage;
    };
}
