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
  };

  config = {
    # Similar to variable assignments in programming languages,
    # it is used to assign values to the options declared in options.
    environment.etc."bonfire-test" = {
      text = "${cfg.flavor}";
    };
  };
}
