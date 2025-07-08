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
      bonfire = {
        image = "docker.io/bonfirenetworks/bonfire:1.0.0-rc.1.24-social-amd64";
        # We connect everything to the host network,
        # this way we can use Nix provides services
        # such as Postgres.
        networks = [ "host" ];
        volumes = [ "/var/lib/bonfire/uploads:/opt/app/data/uploads" ];
        environment = {
          # DB settings
          POSTGRES_DB = "bonfire";
          POSTGRES_USER = "bonfire";
          POSTGRES_HOST = "localhost";
          # Mail settings
          # MAIL_DOMAIN = "FQDN";
          # MAIL_FROM = "name@FQDN";
          # MAIL_BACKEND = "backend";
          # MAIL_PORT = "465";
          # MAIL_SSL = "true";
          # Instance settings
          SEARCH_MEILI_INSTANCE = "http://localhost:7700";
          FLAVOUR = "social";
          PORT = "4000";
          SERVER_PORT = "4000";
          PUBLIC_PORT = "443";
          # HOSTNAME = "FQDN";
          # Technical settings
          SEEDS_USER = "root";
          MIX_ENV = "prod";
          PLUG_BACKEND = "bandit";
          APP_NAME = "Bonfire";
          ERLANG_COOKIE = "bonfire_cookie";
        };
      };
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
