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
      meilisearch = {
        image = "docker.io/getmeili/meilisearch:v1.14";
        # We connect everything to the host network,
        # this way we can use Nix provides services
        # such as Postgres.
        networks = [ "host" ];
        volumes = [ "/var/lib/meilisearch/meili_data:/meili_data" "/var/lib/meilisearch/data.ms:/data.ms" ];
        environment = {
          # Disable telemetry
          MEILI_NO_ANALYTICS = "true";
        };
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
