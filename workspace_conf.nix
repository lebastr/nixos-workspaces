{ container_name,
  host_config,
  workspace_config,
  home-manager,
  pkgs,
  lib,
  ...
}:


with rec {
  inherit (host_config.container-workspace) username workspace-dir nix-src;
  host_userUid = host_config.users.users.${username}.uid;
};

lib.mkIf (workspace_config != null)
  {
    bindMounts = let
      workspace_dir = {
        workspace_dir = {
          hostPath = "${workspace-dir}/${container_name}";
          mountPoint = "/home/user";
          isReadOnly = false;
        };
      };
      wayland = if workspace_config.forwardHostWayland then
        {
          waylandDisplay = {
            hostPath = "/run/user/${toString host_userUid}/wayland-1";
            mountPoint = "/run/user/${toString host_userUid}/wayland-1";
          };

          xDisplay = {
            hostPath = "/tmp/.X11-unix";
            mountPoint = "/tmp/.X11-unix";
          };
        } else { };
      pulse_audio = if workspace_config.forwardHostPulseAudio then
        {
          pulseaudio = {
            hostPath = "/run/user/${toString host_userUid}/pulse";
            mountPoint = "/run/user/${toString host_userUid}/pulse";
          };
        } else { };
      dri = if workspace_config.forwardHostDri then {
        dri = {
          hostPath = "/dev/dri";
          mountPoint = "/dev/dri";
          isReadOnly = true;
        };
      } else { };
      fuseDevice = if workspace_config.forwardFuseDevice then {
        fuseDevice = { hostPath = "/dev/fuse";
                       isReadOnly = false;
                       mountPoint = "/dev/fuse";
                     };
      } else { };
    in
      workspace_dir // wayland // pulse_audio // dri // fuseDevice;
    
    allowedDevices = lib.optional workspace_config.forwardHostDri { node = "/dev/dri/renderD128"; modifier = "rw"; } ++
                     lib.optional workspace_config.forwardFuseDevice { node = "/dev/fuse"; modifier = "rw"; };

    config = {
      system.stateVersion = host_config.system.stateVersion;
      imports = [ home-manager.nixosModules.home-manager ];
      
      sound.enable = true;
      hardware.pulseaudio.enable = true;
      hardware.opengl = {
        enable = true;
        extraPackages = host_config.hardware.opengl.extraPackages;
      };
      
      environment.systemPackages = workspace_config.systemPackages;
      
      users.users.user = {
        uid = host_userUid;
        isNormalUser = true;
        initialPassword = "secret";
        extraGroups = [ "render" ];
      };
      
      home-manager = {
        useGlobalPkgs = true;
        users.user = {
          # (4)
          programs.direnv.enable = workspace_config.nix-direnv;
          programs.direnv.nix-direnv.enable = workspace_config.nix-direnv;
          programs.bash.enable = true;

          home.packages = workspace_config.homePackages;
          home.sessionVariables =
            (if workspace_config.forwardHostWayland then
              {
                WAYLAND_DISPLAY                     = "wayland-1";
                QT_QPA_PLATFORM                     = "wayland";
                QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                SDL_VIDEODRIVER                     = "wayland";
                CLUTTER_BACKEND                     = "wayland";
                MOZ_ENABLE_WAYLAND                  = "1";
                _JAVA_AWT_WM_NONREPARENTING         = "1";
                _JAVA_OPTIONS                       = "-Dawt.useSystemAAFontSettings=lcd";
                DISPLAY                             = ":0";
              } else { }) // {
                XDG_RUNTIME_DIR                     = "/run/user/${toString host_userUid}/";
                NIX_PATH = lib.mkForce "nixpkgs=${pkgs.path}";
              };

          home.stateVersion = host_config.system.stateVersion;
        };
      };
      
      # (5)
      systemd.services.fix-nix-dirs = let
        profileDir = "/nix/var/nix/profiles/per-user/user";
        gcrootsDir = "/nix/var/nix/gcroots/per-user/user";
      in {
        script = ''
                   #!${pkgs.stdenv.shell}
                   set -euo pipefail

                   mkdir -p ${profileDir} ${gcrootsDir}
                   chown user:root ${profileDir} ${gcrootsDir}
                '';
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
      };

      systemd.services.fix-run-permission = {
        script = ''
                  #!${pkgs.stdenv.shell}
                  set -euo pipefail

                  chown user:users /run/user/${toString host_userUid}
                  chmod 700 /run/user/${toString host_userUid}
                '';
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  }
