{ lib, config, pkgs, home-manager, ... }:

with lib;
with types;

let host_config = config;
in 
{
  options = {
    container-workspace = mkOption {
      type = submodule (
        { config, ... }:
        {
          options = {
            username = mkOption {
              type = addCheck str (name: hasAttr name host_config.users.users);
            };

            workspace-dir = mkOption {
              type = path;
            };

            nix-src = mkOption {
              type = nullOr path;
              default = null;
            };
          };
        }
      );
    };

    containers = mkOption {
      type = attrsOf (submodule (
        { name, config, ... }@containerSubmoduleArgs:
        let args = {
              inherit host_config home-manager pkgs lib;
              container_name = name;
              workspace_config = config.workspace;
            };
        in 
          {
            options.workspace = mkOption {
              type = nullOr (submodule (import ./workspace_opts.nix));
              default = null;
            };

            config = import ./workspace_conf.nix args;
          }
      ));
    };
  };
}
