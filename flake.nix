{
  description = "Isolated workspaces are implemented through a NixOS container";
  outputs = { self, nixpkgs, home-manager }: {
    nixosModules.workspaces = import ./container-workspace.nix;
  };
}
