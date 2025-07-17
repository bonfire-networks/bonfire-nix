{ config, pkgs, ... }:

{
  imports =
    [
    ./hardware-configuration.nix
    ];

  nix.settings.experimental-features =["nix-command" "flakes"];

  time.timeZone = "europe/london";

  boot = {
   kernelPackages = pkgs.linuxPackages_6_1;
   supportedFilesystems = [ "btrfs"];

   loader.grub = {
    enable = true;
    version = 2;
    forceInstall = true;
    device = "/dev/sda";
   };
  };

  virtualisation.docker {
   enable = true;
  };

  virtualisation.oci-containers = {
    # backend defaults to "podman"
    backend = "docker";
    containers = {
      bonfire = {
        image = "docker.io/bonfirenetworks/bonfire:1.0.0-rc.2.1-social-amd64";
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

  networking = {
   hostName = "nixos-vm";
   useDHCP = false;

   interfaces = {
    eth0.useDHCP = true;
  };

  firewall = {
   enable = true;
   allowedTCPPorts =[];
   allowedUDPPorts =[];
   };
  };

  nix = {
     gc = {
       automatic = true;
       dates = "monthly";
       options = "--delete-older-than 30d";
       };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
  };

  services.fail2ban.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbtpVOYTYF0aCPNpQSUoU7efLH13RwCwiN4rmhl3RQN mark.williams@protonmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPLo9gQ9VwhKuaBSL84liznZT1Eov71DkcKqZFJZKgfgo+Lug4mf03WTrp5/BJEYuPjj4P4RAkakX/5NjHf7ypBr+sBBo02HH5AgJB2GRhcDVJTiJwaG7ghl5kN+lDk+yD5YWckSVHgMVmukEtEf5P4EH4bRfIBaF76md1qt5cG6/NXGDpvkTE1y+40OdjI6dj1/4StktaQiqPI09zPMFbJewxR2Npiua5q1PDXSi677JAeO2FMv16wJpaJXczkSwuQIv5sf3/DgYi/ZpAuzdm4+nlj/1xKTH0fVAdP+gfwDKiOIuIYqjata2+MHgVkkJyIGlgOmTZPWRY1VuooAWdIAKZajpNX5sGePD1tzuO9yOiKTJkq2Q3W3V7xFRFEhAjMUid3/5Q9HZ7Ymms+4lz1tRu9aJj8hKVdiL70L6Qk2zi7uGgbZaKym69B5O3qyDcMT/bX/83pEhL9tQ2WsSwQD7ISPgw1V8+iKgh76I0IBkNT3tUiXeD+EYjutSCYXSajdfk4eMfuNgA+HMZKEyMhfta+SxfRObGgHhusjiiuhn5Tak2vbLf1DG8+2cJE8LTHtWhm5PBgBsTQS5EPVh5HONRy2Ya+KTzNMOskmkT/FZESKNuCWqb+GOEmx2VXzC0xW/GBnDiEfwxV3olcHOrX88JeBbzRTDcovfWUJzKZQ== goodoldpaul@autistici.org"
  ];

  users.users.mark.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFbtpVOYTYF0aCPNpQSUoU7efLH13RwCwiN4rmhl3RQN mark.williams@protonmail.com"
  ];

  users.users.giacomo.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPLo9gQ9VwhKuaBSL84liznZT1Eov71DkcKqZFJZKgfgo+Lug4mf03WTrp5/BJEYuPjj4P4RAkakX/5NjHf7ypBr+sBBo02HH5AgJB2GRhcDVJTiJwaG7ghl5kN+lDk+yD5YWckSVHgMVmukEtEf5P4EH4bRfIBaF76md1qt5cG6/NXGDpvkTE1y+40OdjI6dj1/4StktaQiqPI09zPMFbJewxR2Npiua5q1PDXSi677JAeO2FMv16wJpaJXczkSwuQIv5sf3/DgYi/ZpAuzdm4+nlj/1xKTH0fVAdP+gfwDKiOIuIYqjata2+MHgVkkJyIGlgOmTZPWRY1VuooAWdIAKZajpNX5sGePD1tzuO9yOiKTJkq2Q3W3V7xFRFEhAjMUid3/5Q9HZ7Ymms+4lz1tRu9aJj8hKVdiL70L6Qk2zi7uGgbZaKym69B5O3qyDcMT/bX/83pEhL9tQ2WsSwQD7ISPgw1V8+iKgh76I0IBkNT3tUiXeD+EYjutSCYXSajdfk4eMfuNgA+HMZKEyMhfta+SxfRObGgHhusjiiuhn5Tak2vbLf1DG8+2cJE8LTHtWhm5PBgBsTQS5EPVh5HONRy2Ya+KTzNMOskmkT/FZESKNuCWqb+GOEmx2VXzC0xW/GBnDiEfwxV3olcHOrX88JeBbzRTDcovfWUJzKZQ== goodoldpaul@autistici.org"
  ];


  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = [ "bonfire" ];
    ensureUsers = [
      {
        name = "bonfire";
      }
    ];
    authentication = ''
      local   all             all                                     md5
      host    all             all             127.0.0.1/32            md5
      host    all             all             ::1/128                 md5
    '';
  };

  users.users.mark = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  users.users.giacomo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  users.users.bonfire = {
    isSystemUser = true;
    home = "/var/lib/bonfire";
    createHome = true;
    group = "bonfire";
  };
  users.groups.bonfire = {};

  system.stateVersion = "23.11";
}
