{ config, pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "bonfire" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  virtualisation.docker = {
    enable = true;
  };

  virtualisation.oci-containers = {
    # backend defaults to "podman"
    backend = "docker";
    containers = {
      foo = {
        # ...
      };
    };
  };

  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    initialPassword = "test";
  };

  system.stateVersion = "24.05";
}
