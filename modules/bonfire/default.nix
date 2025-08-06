{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bonfire;
in {
  options.bonfire = {
    # Similar to variable declarations in programming languages,
    # it is used to declare configurable options.

    # OCI options
    backend = lib.mkOption {
      type = lib.types.str;
      default = "docker";
      description = ''
        OCI backend that will be passed to
        virtualization.oci-containers.backend
      '';
    };
    networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "host" ];
      example = [ "host" ];
      description = ''
        The OCI networks name where the Bonfire container will be attached.
      '';
    };
    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/bonfirenetworks/bonfire";
      description = ''
        The OCI image that will be used to run Bonfire
      '';
    };
    arch = lib.mkOption {
      type = lib.types.str;
      default = "amd64";
      description = ''
        The CPU architecture that will run Bonfire
      '';
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "latest";
      description = ''
        Bonfire version to be instantiated
      '';
    };
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "social";
      description = ''
        Bonfire flavor to be instantiated
      '';
    };

    # DB options
    postgres-db = lib.mkOption {
      type = lib.types.str;
      default = "bonfire";
      description = ''
        The name of the Postgres database used by Bonfire
      '';
    };
    postgres-user = lib.mkOption {
      type = lib.types.str;
      default = "bonfire";
      description = ''
        The name of the user used by Bonfire to connect to the Postgres database
      '';
    };
    postgres-package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_15;
      description = ''
        PostgreSQL package to use.
      '';
    };

    # Mail options
    mail-server = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The SMTP domain of the mail server.
      '';
    };
    mail-domain = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The bit after @ in your email.
      '';
    };
    mail-user = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The bit before @ in your email.
      '';
    };
    mail-from = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The email address from which Bonfire will send emails.
      '';
    };
    mail-port = lib.mkOption {
      type = lib.types.str;
      default = "465";
      description = ''
        The port of the SMTP service on your mail server.
      '';
    };
    mail-ssl = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to use SSL for the connection to the SMTP server.
      '';
    };

    # Web options
    hostname = lib.mkOption {
      type = lib.types.str;
      description = ''
        The domain name of the Bonfire instance
      '';
    };
    meilisearch-instance = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The meilisearch instance used by Bonfire.
      '';
    };
    port = lib.mkOption {
      type = lib.types.str;
      default = "4000";
      description = ''
        The internal port where Bonfire will be exposed.
      '';
    };
    public-port = lib.mkOption {
      type = lib.types.str;
      default = "443";
      description = ''
        The public port where Bonfire will be exposed.
      '';
    };

    # State options
    uploadsDir = mkOption {
      type = types.path;
      defaultText = "/var/lib/bonfire";
      description = ''
        The directory where Bonfire writes uploaded files.
      '';
    };

  };

  config = {
    # Similar to variable assignments in programming languages,
    # it is used to assign values to the options declared in options.
    services.postgresql = {
      enable = true;
      package = cfg.postgres-package;
      ensureDatabases = [ "${cfg.postgres-db}" ];
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database DBuser origin-address auth-method
        local all       all     trust
        # ipv4
        host  all      all     127.0.0.1/32   trust
        # ipv6
        host all       all     ::1/128        trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE ${cfg.postgres-user} LOGIN CREATEDB;
        CREATE DATABASE ${cfg.postgres-db};
        GRANT ALL PRIVILEGES ON DATABASE ${cfg.postgres-db} TO ${cfg.postgres-user};
      '';
    };
    virtualisation.docker = {
     enable = true;
    };

    virtualisation.oci-containers = {
      # backend defaults to "podman"
      backend = "${cfg.backend}";
      containers = {
        bonfire = {
          image = "${cfg.image}:${cfg.version}-${cfg.flavor}-${cfg.arch}";
          # We connect everything to the host network,
          # this way we can use Nix provides services
          # such as Postgres.
          networks = cfg.networks;
          volumes = [ "${cfg.uploadsDir}:/opt/app/data/uploads" ];
          environment = {
            # DB settings
            POSTGRES_DB = "${cfg.postgres-db}";
            POSTGRES_USER = "${cfg.postgres-user}";
            POSTGRES_HOST = "${postgres-host}";
            # Mail settings
            MAIL_DOMAIN = "${cfg.mail-domain}";
            MAIL_FROM = "${cfg.mail-from}";
            MAIL_BACKEND = "${cfg.mail-backend}";
            MAIL_PORT = "${cfg.mail-port}";
            MAIL_SSL = "${cfg.mail-ssl}";

            # Instance settings
            SEARCH_MEILI_INSTANCE = "${cfg.meilisearch-instance}";
            FLAVOUR = "${cfg.flavor}";
            PORT = "${cfg.port}";
            SERVER_PORT = "${cfg.port}";
            PUBLIC_PORT = "${cfg.public-port}";
            HOSTNAME = "${cfg.hostname}";

            # Technical settings
            SEEDS_USER = "root";
            MIX_ENV = "prod";
            PLUG_BACKEND = "bandit";
            APP_NAME = "Bonfire";
            ERLANG_COOKIE = "bonfire_cookie";
          };
        };
      };
    };
  };
}
