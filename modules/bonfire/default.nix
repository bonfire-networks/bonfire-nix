{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bonfire;
in {
  options.bonfire = {
    # Similar to variable declarations in programming languages,
    # it is used to declare configurable options.

    # OCI options
    # FIXME: Allow changing OCI backend.
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
      # We connect everything to the host network,
      # this way we can use Nix provided services
      # such as Postgres.
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
    postgres-host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = ''
        The hostname where the Postgres db for Bonfire is running.
      '';
    };
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
      default = pkgs.postgresql_16;
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
    mail-backend = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The MAIL_BACKEND variable.
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
      default = "http://localhost:7700";
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
      type = lib.types.path;
      default = "/var/lib/bonfire";
      defaultText = "/var/lib/bonfire";
      description = ''
        The directory where Bonfire writes uploaded files.
      '';
    };

    # Secrets
    secret-key-base = mkOption {
      type = lib.types.path;
      default = "/run/secrets/bonfire/secret_key_base";
      defaultText = "/run/secrets/bonfire/secret_key_base";
      description = ''
         SECRET_KEY_BASE Bonfire secret file path.
      '';
    };
    signing-salt = mkOption {
      type = lib.types.path;
      default = "/run/secrets/bonfire/signing_salt";
      defaultText = "/run/secrets/bonfire/signing_salt";
      description = ''
        SIGNING_SALT Bonfire secret file path.
      '';
    };
    encryption-salt = mkOption {
      type = lib.types.path;
      default = "/run/secrets/bonfire/encryption_salt";
      defaultText = "/run/secrets/bonfire/encryption_salt";
      description = ''
        ENCRYPTION_SALT Bonfire secret file path.
      '';
    };
    mail-key = mkOption {
      type = with lib.types; nullOr path;
      default = null;
      defaultText = "/run/secrets/bonfire/mail_key";
      description = ''
        MAIL_KEY Bonfire secret file path.
      '';
    };
    mail-private-key = mkOption {
      type = with lib.types; nullOr path;
      default = null;
      defaultText = "/run/secrets/bonfire/mail_private_key";
      description = ''
        MAIL_PRIVATE_KEY Bonfire secret file path.
      '';
    };
    mail-password = mkOption {
      type = with lib.types; nullOr path;
      default = null;
      defaultText = "/run/secrets/bonfire/mail_password";
      description = ''
        MAIL_KEY Bonfire secret file path.
      '';
    };

    # Systemd service
    requires = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "postgresql.service" "docker-meilisearch.service" ];
      example = [ "postgresql.service" "docker-meilisearch.service" ];
      description = ''
        The systemd dependencies of the Bonfire service.
      '';
    };
    auto-start = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to use auto start Bonfire at boot.
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
      extensions = ps: with ps; [ pkgs.postgis ];
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
          networks = cfg.networks;
          volumes = [
            "${cfg.uploadsDir}:/opt/app/data/uploads"
            "${cfg.secret-key-base}:${cfg.secret-key-base}:ro"
            "${cfg.signing-salt}:${cfg.signing-salt}:ro"
            "${cfg.encryption-salt}:${cfg.encryption-salt}:ro"
          ] ++
          (if cfg.mail-password != null then [ "${cfg.mail-password}:${cfg.mail-password}:ro" ] else []) ++
          (if cfg.mail-key != null then [ "${cfg.mail-key}:${cfg.mail-key}:ro" ] else []) ++
          (if cfg.mail-private-key != null then [ "${cfg.mail-private-key}:${cfg.mail-private-key}:ro" ] else []);
          entrypoint = "/bin/sh";
          cmd = [ "-c" "${
                    if cfg.mail-key != null then "export MAIL_KEY=\"$(cat ${cfg.mail-key})\"; " else ""
                    } ${
                    if cfg.mail-private-key != null then "export MAIL_PRIVATE_KEY=\"$(cat ${cfg.mail-private-key})\"; " else ""
                    } ${
                    if cfg.mail-password != null then "export MAIL_PASSWORD=\"$(cat ${cfg.mail-password})\"; " else ""
                    } export SECRET_KEY_BASE=\"$(cat ${cfg.secret-key-base})\"; export SIGNING_SALT=\"$(cat ${cfg.signing-salt})\"; export ENCRYPTION_SALT=\"$(cat ${cfg.encryption-salt})\"; exec -a ./bin/bonfire ./bin/bonfire start" ];
          environment = {
            # DB settings
            DATABASE_URL = "ecto://${cfg.postgres-user}@${cfg.postgres-host}/${cfg.postgres-db}";
            # POSTGRES_DB = "${cfg.postgres-db}";
            # POSTGRES_USER = "${cfg.postgres-user}";
            # POSTGRES_HOST = "${cfg.postgres-host}";

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

            # Mail settings
          } // (if cfg.mail-domain != null then { MAIL_DOMAIN =  "${cfg.mail-domain}"; } else {}) //
          (if cfg.mail-from != null then { MAIL_FROM = "${cfg.mail-from}"; } else {}) //
          (if cfg.mail-backend != null then { MAIL_BACKEND = "${cfg.mail-backend}"; } else {}) //
          (if cfg.mail-port != null then { MAIL_PORT = "${cfg.mail-port}"; } else {}) //
          (if cfg.mail-ssl then { MAIL_SSL = "${lib.trivial.boolToString cfg.mail-ssl}"; } else {});
        };

        meilisearch = {
          image = "docker.io/getmeili/meilisearch:v1.14";
          networks = cfg.networks;
          volumes = [
            "/var/lib/meilisearch/meili_data:/meili_data"
            "/var/lib/meilisearch/data.ms:/data.ms"
          ];
          environment = {
            # Disable telemetry
            MEILI_NO_ANALYTICS = "true";
          };
        };
      };
    };

    systemd.services.docker-bonfire = {
      requires = cfg.requires;
      after = cfg.requires;
    } // (if cfg.auto-start then {} else { wantedBy = lib.mkForce [ ]; });
  };
}
