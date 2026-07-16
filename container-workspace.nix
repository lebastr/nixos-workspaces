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

  config = mkIf (any (c: c.workspace != null && c.workspace.forwardHostScreencast)
                     (attrValues host_config.containers)) {
    # One shared filtered D-Bus proxy exposing ONLY the desktop portal
    # (org.freedesktop.portal.Desktop) to workspaces that opt into
    # forwardHostScreencast. It runs in the workspace user's graphical session,
    # where the compositor (niri) provides the portal. D-Bus is per-connection,
    # so a single proxy instance serves all such containers without cross-talk.
    systemd.user.services.xdg-dbus-proxy-portal = {
      description = "Filtered D-Bus proxy exposing the desktop portal to workspaces";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        # RuntimeDirectory creates $XDG_RUNTIME_DIR/portal-proxy; Preserve keeps
        # the directory inode stable across restarts so the container's directory
        # bind mount stays valid. ExecStartPre clears a stale socket so the proxy
        # can re-bind cleanly.
        RuntimeDirectory = "portal-proxy";
        RuntimeDirectoryPreserve = "yes";
        ExecStartPre = "-${pkgs.coreutils}/bin/rm -f %t/portal-proxy/bus";
        ExecStart = "${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy"
          + " unix:path=%t/bus %t/portal-proxy/bus"
          + " --filter --talk=org.freedesktop.portal.Desktop";
        Restart = "on-failure";
      };
    };
  };
}
