{ config, lib, ... }:
let
  cfg = config.my.user;
  extraGroups = cfg.extraGroups;

  # Import my secrets (e.g. hashed passwords).
  secrets = import ../secrets.nix;
  # Import my common configuration data (e.g. public keys).
  data = import ../data.nix;
in
{
  options.my.user = {
    enable = lib.mkEnableOption "Enables my user.";
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    # Define my user account.
    users.users.indiv0 = {
      uid = 1000;
      isNormalUser = true;
      # Enable 'sudo' for the user.
      extraGroups = [ "wheel" ] ++ extraGroups;
      initialHashedPassword = secrets.hashedIndiv0Password;
      openssh.authorizedKeys.keys = [
        data.keys.systems.lap-ca-nik-01
        data.keys.systems.phn-ca-nik-01
      ];
    };
  };
}