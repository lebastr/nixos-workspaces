{ lib, ... }:

with lib;
with types;

{
  options = {
    forwardHostWayland = mkOption {
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
