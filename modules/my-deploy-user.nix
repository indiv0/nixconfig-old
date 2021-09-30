{ config, lib, ... }:
let
  cfg = config.my.deploy-user;

  # Import my secrets (e.g. hashed passwords).
  secrets = import ../secrets.nix;
  # Import my common configuration data (e.g. public keys).
  data = import ../data.nix;
in
{
  options.my.deploy-user.enable = lib.mkEnableOption "Enables my deploy user.";

  config = lib.mkIf cfg.enable {
    # Define a user for deployments.
    users.users.deploy = {
      uid = 1001;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ data.keys.systems.lap-ca-nik-01 ];
    };
    # It needs to be a trusted user to copy things into the store.
    nix.trustedUsers = [ "deploy" ];
    # It needs to be able to execute things as sudo at arbitrary paths to be
    # able to switch generations and things like that.
    security.sudo.extraRules = [{
      users = [ "deploy" ];
      commands = [{
        command = "ALL";
        options = [ "SETENV" "NOPASSWD" ];
      }];
    }];
  };
}