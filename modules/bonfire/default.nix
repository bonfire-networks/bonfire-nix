{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.bonfire;
in {
  options.bonfire = {
    # Similar to variable declarations in programming languages,
    # it is used to declare configurable options.
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
  };
}
