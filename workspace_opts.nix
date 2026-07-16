{ lib, ... }:

with lib;
with types;

{
  options = {
    forwardHostWayland = mkOption {
      type = bool;
      default = false;
    };

    forwardHostX = mkOption {
      type = bool;
      default = false;
    };

    forwardFuseDevice = mkOption {
      type = bool;
      default = false;
    };
    
    forwardHostPulseAudio = mkOption {
      type = bool;
      default = false;
    };
    
    forwardHostDri = mkOption {
      type = bool;
      default = false;
    };

    # Forward the host desktop portal (org.freedesktop.portal.Desktop) into the
    # container via a filtered xdg-dbus-proxy, enabling e.g. screen sharing in
    # browsers. Requires the host to run a compositor providing the portal
    # (niri) in the workspace user's session.
    forwardHostScreencast = mkOption {
      type = bool;
      default = false;
    };

    # TODO What exact type is here?
    systemPackages = mkOption {
      type = listOf attrs;
      default = [ ];
    };
    
    homePackages = mkOption {
      type = listOf attrs;
      default = [ ];
    };

    nix-direnv = mkOption {
      type = bool;
      default = false;
    };
  };
}
