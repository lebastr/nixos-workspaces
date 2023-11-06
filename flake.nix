{
  description = "Isolated workspaces are implemented through a NixOS container";
  outputs = { self }: {
    nixosModules.workspaces = import ./container-workspace.nix;
  };
}
