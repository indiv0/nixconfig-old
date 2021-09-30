{ config, lib, pkgs, ... }:
let
  cfg = config.my.smartd;
in
{
  options.my.smartd.enable = lib.mkEnableOption "Enabled my smartd monitoring";
  config = lib.mkIf cfg.enable {
    # Enable `smartd` daemon from `smartmontools` package.
    services.smartd.enable = true;
    # Common default options for autodetected devices.
    #
    # Example turns on SMART Automatic Offline Testing on startup, and
    # schedules short self-tests daily at 3 AM (excluding Sunday and Monday),
    # and long self-tests weekly (Sunday).
    services.smartd.defaults.autodetected = "-a -o on -s (S/../../(2|3|4|5|6)/03|L/../../7/03)";
    # Whether to send e-mail notifications.
    services.smartd.notifications.mail.enable = true;
    # Recipient of notification messages.
    services.smartd.notifications.mail.recipient = "nikita@frecency.com";
    # Sender of the notification messages. Acts as the value of `email` in the
    # emails' `From: ...` field.
    services.smartd.notifications.mail.sender = "root@${config.networking.hostName}.olympus.hax.rs";
    # Whether to send a test notification on startup.
    services.smartd.notifications.test = true;
  };
}