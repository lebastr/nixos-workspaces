{
  description = "Isolated workspaces are implemented through a NixOS container";

  inputs = {
    home-manager.url = "github:nix-community/home-manager";
    nixpkgs.url = "github:/NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosModules.workspaces = { config, nix-doom-emacs }: import ./container-workspace.nix { config = config;
                                                                             lib = nixpkgs.lib;
                                                                             pkgs = nixpkgs;
                                                                             home-manager = home-manager;
                                                                           };
  };
}
