{ config, lib, pkgs, ... }:
let
  cfg = config.my.zfs;
in
{
  options.my.zfs.enable = lib.mkEnableOption "Enabled my ZFS trim, snapshot, scrub, and ZED email alerts";
  config = lib.mkIf cfg.enable {
    # Regular scrubbing of ZFS pools is recommended. The default scrub interval
    # is a week, but can be changed. All pools are scrubbed by default.
    services.zfs.autoScrub.enable = true;
    # Systemd calendar expression when to scrub ZFS pools. See systemd.time(7).
    # Default: "Sun, 02:00"
    services.zfs.autoScrub.interval = "Wed, 01:00";

    # Enable automatic snapshots for any datasets with the
    # `com.sun:auto-snapshot=true` property set.
    #
    # By default, the auto-snapshot service will keep the latest
    # four 15-minute, 24 hourly, 7 daily, 4 weekly, and 12 monthly
    # snapshots. You can globally override this configuration.
    # For details, see:
    # https://nixos.wiki/wiki/NixOS_on_ZFS
    services.zfs.autoSnapshot.enable = false;
    # Flags to pass to the `zfs-auto-snapshot` command.
    #
    # Run `zfs-auto-snapshot` (without any arguments) to see available flags.
    #
    # If it's not too inconvenient for snapshots to have timestamps in UTC, it
    # is suggested that you append --utc to the list of default options (see
    # example).
    #
    # Otherwise, snapshot names can cause name conflicts or apparent time
    # reversals due to daylight savings, timezone or other date/time changes.
    #
    # Default: `"-k -p"`
    services.zfs.autoSnapshot.flags = "-k -p --utc";

    # Periodically (by default once a week) perform a manual
    # trim of all pools.
    services.zfs.trim.enable = true;

    services.zfs.zed.settings = {
      # Absolute path to the debug output file.
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      # Email address of the zpool administrator for receipt of notifications;
      # multiple addresses can be specified if they are delimited by
      # whitespace. Emails will only be sent in `ZED_EMAIL_ADDR` is defined.
      # Disabled by default.
      ZED_EMAIL_ADDR = "nikita@frecency.com";
      # Notification verbosity.
      #
      # If set to 0, suppress notification if the pool is healthy.
      # If set to 1, send notification regardless of pool health.
      ZED_NOTIFY_VERBOSE = 1;
      # Send notifications for 'ereport.fs.zfs.data' events.
      # Disabled by default, any non-empty value will enable the feature.
      ZED_NOTIFY_DATA = "enabled";
    };
  };
}