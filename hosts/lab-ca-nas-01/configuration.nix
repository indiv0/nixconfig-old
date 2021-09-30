# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  # Load secrets
  secrets = import ../../secrets.nix;
  # Load common configuration data (e.g. public keys).
  data = import ../../data.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Import my modules.
    ../../modules/my-deploy-user.nix
    ../../modules/my-smartd.nix
    ../../modules/my-user.nix
    ../../modules/my-zfs.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  networking.hostName = "lab-ca-nas-01";

  # Set NIX_PATH for NixOS config and nixpkgs.
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/etc/nixos/hosts/lab-ca-nas-01/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # Disable `boot.loader.efi.canTouchEfiVariables` as it is mutually
  # exclusive with `boot.loader.grub.efiInstallAsRemovable`.
  # boot.loader.efi.canTouchEfiVariables = true;

  # Configure the system to boot with grub and manage /boot automatically.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";

  # Mirror all UEFI files, kernels, grub menus, and other things needed to
  # to the other drive.
  boot.loader.grub.mirroredBoots = [
    {
      devices = [ "/dev/disk/by-uuid/68F4-D4F4" ];
      path = "/boot-fallback";
    }
  ];

  # Configure the system to support ZFS.
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "99096350";

  # Request encryption credentials to unlock the ZFS dataset at boot.
  boot.zfs.requestEncryptionCredentials = true;

  # Set your time zone.
  time.timeZone = "Canada/Eastern";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.nameservers = [ "172.30.194.1" ];
  networking.domain = "olympus.hax.rs";
  networking.defaultGateway.address = "172.30.194.1";
  networking.defaultGateway.interface = "eno1";
  networking.interfaces.eno1.ipv4.addresses = [{
    address = "172.30.194.16";
    prefixLength = 24;
  }];
  # Enable the systemd DNS resolver daemon.
  services.resolved.enable = true;
  services.resolved.domains = [ "olympus.hax.rs" ];

  boot.kernelParams = [
    # Configure the kernel to assign a static IP in the initrd.
    # This is necessary as using DHCP can result in a race condition where
    # udhcpc fails because the interface isn't ready yet.
    #
    # ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:
    #   <autoconf>:<dns0-ip>:<dns1-ip>:<ntp0-ip>
    "ip=172.30.194.16::172.30.194.1:255.255.255.0:lab-ca-nas-01:eno1"
  ];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Don't allow mutation of users outside of the config.
  users.mutableUsers = false;

  # Set a root password.
  users.users.root.initialHashedPassword = secrets.hashedRootPassword;

  # Define my user account.
  my.user.enable = true;

  # Define my user account for deployments.
  my.deploy-user.enable = true;

  # Enable ZFS trim, snapshot, scrub, and ZED email alerts.
  my.zfs.enable = true;

  # Enable periodic smartd monitoring with email notifications.
  my.smartd.enable = true;

  security.sudo.extraRules = [
    # Don't require a sudo password for `sanoid`. This is necessary for remote
    # machines to be able to use sudo in scripts.
    {
      users = [ "sanoid" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/zfs";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # persist our nix configuration across reboots.
  environment.etc."nixos".source = "/persist/etc/nixos";

  # machine-id is used by systemd for the journal; if you don't persist this
  # file you won't be able to easily use journalctl to look at journals for
  # previous boots.
  environment.etc."machine-id".source = "/persist/etc/machine-id";

  # if you want to run an openssh daemon, you may want to store the host keys
  # across reboots.
  environment.etc."ssh/ssh_host_rsa_key".source = "/persist/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source = "/persist/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source = "/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/persist/etc/ssh/ssh_host_ed25519_key.pub";

  # Add a dropbear ssh service in initrd for the password prompt.
  boot.initrd.network = {
    # This will use udhcp to get an ip address.
    # Make sure you have added the kernel module for your network driver to
    # `boot.initrd.availableKernelModules`, so your initrd can load it!
    # Static IP addresses might be configured using the `ip` argument in
    # kernel command line:
    # https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt
    enable = true;
    ssh = {
      enable = true;
      # To prevent SSH from freaking out because a different host key is used,
      # a different port for dropbear is useful (assuming the same host also
      # has a normal sshd running).
      port = 2222;
      # Generate your keys with ssh-keygen:
      #
      # $ ssh-keygen -t rsa -N "" -f /persist/etc/secrets/initrd/ssh_host_rsa_key
      # $ ssh-keygen -t ed25519 -N "" -f /persist/etc/secrets/initrd/ssh_host_ed25519_key
      hostKeys = [
        /persist/etc/secrets/initrd/ssh_host_rsa_key
        /persist/etc/secrets/initrd/ssh_host_ed25519_key
      ];
      # Public SSH key used for login.
      authorizedKeys = [
        data.keys.systems.lap-ca-nik-01
        data.keys.systems.phn-ca-nik-01
      ];
    };
    # This will automatically load the ZFS password prompt on login and kill
    # the other prompt so boot can continue.
    postCommands = ''
      zpool import zpool-fnazxg
      echo "zfs load-key -a; killall zfs" >> /root/.profile
    '';
  };

  # Install useful packages globally.
  environment.systemPackages = with pkgs; [
    tree
    vim
    # Add the lzop and mbuffer packages for syncoid to use when copying over
    # ZFS datasets.
    lzop
    mbuffer
  ];

  # Use systemd's tmpfiles.d rules to create a symlink between system
  # directories and their persistent equivalents.
  systemd.tmpfiles.rules = [
    "L /var/spool/postfix - - - - /persist/var/spool/postfix"
  ];

  # Automatically run the garbage collector at a specific time. By default
  # runs at 03:15 daily.
  nix.gc.automatic = true;

  # Enable the APC UPS daemon. `apcupsd` monitors your UPS and permits
  # orderly shutdown of your computer in the event of a power failure. User
  # manual:
  # https://www.apcupsd.com/manual/manual.html. Note that `apcupsd` runs as
  # root (to allow shutdown of the computer). You can check the status of
  # your UPS with the `apcaccess` command.
  services.apcupsd.enable = true;
  # Contents of the runtime configuration file, `acpupsd.conf`.
  # See `man apcupsd.conf` for details.
  services.apcupsd.configText = ''
    # Autodetect USB UPSes.
    UPSCABLE usb
    UPSTYPE usb
    # Limit network access to localhost.
    DEVICE
    # Enable the network information server.
    NETSERVER on
    NISIP 0.0.0.0
    # Shutdown the system when the battery level is below 30 percent.
    BATTERYLEVEL 30
  '';

  # Whether to enable Tailscale client daemon.
  services.tailscale.enable = true;

  # Run the Postfix mail server.
  services.postfix.enable = true;
  services.postfix.config = {
    myhostname = "${config.networking.hostName}.olympus.hax.rs";
    relayhost = "[smtp.fastmail.com]:587";
    smtp_sasl_auth_enable = "yes";
    smtp_sasl_password_maps = "hash:/etc/postfix.local/sasl_passwd";
    smtp_sasl_security_options = "noanonymous";
    smtp_use_tls = "yes";
  };
  # Load the passwords from the `sasl_passwd` file.
  systemd.services.postfix.preStart = ''
    ${pkgs.postfix}/sbin/postmap /etc/postfix.local/sasl_passwd
  '';

  # If enabled, NixOS will periodically update the database of files used by
  # the `locate` command.
  services.locate.enable = true;
  # Update the locate database at this interval. Updates by default at 2:15
  # AM every day.
  #
  # The format is described in systemd.time(7).
  services.locate.interval = "hourly";
  # The user to search non-network directories as, using `su`.
  #
  # `mlocate` does not support the `services.locate.localuser` option;
  # updatedb will run as root. Warning for this silenced with
  # `services.locate.localuser = null`.
  #
  # Default: "nobody"
  services.locate.localuser = null;
  # The locate implementation to use.
  services.locate.locate = pkgs.mlocate;
  # The database file to build.
  #
  # NOTE: move this into the `/var/cache/mlocate` directory because we can't
  # bind mount an individual file (i.e., `/var/cache/locatedb`) and we don't
  # want to bind mount the entire `/var/cache` directory.
  #
  # Default: "/var/cache/locatedb"
  services.locate.output = "/var/cache/mlocate/locatedb";

  # Whether to invoke `grub-install` with `--removable`.
  #
  # Unless you turn this on, GRUB will install itself somewhere in
  # `boot.loader.efi.efiSysMountPoint` (exactly where depends on other config
  # variables). If you've set `boot.loader.efi.canTouchEfiVariables` *AND*
  # you are currently booted in UEFI mode, then GRUB will use `efibootmgr` to
  # modify the boot order in the EFI variables of your firmware to includ
  # this location. If you are *not* booted in UEFI mode at the time GRUB is
  # being installed, the NVRAM will not be modified, and your system will not
  # find GRUB at boot time. However, GRUB will still return success so you
  # may miss the warning that gets printed ("
  # `efibootmgr: EFI variables are not supported on this system.`").
  #
  # If you turn this feature on, GRUB will install itself in a special
  # location within `efiSysMountPoint` (namely `EFI/boot/boot$arch.efi`)
  # which the firmwares are hardcoded to try first, regardless of NVRAM EFI
  # variables.
  #
  # To summarize, turn this on if:
  # - You are installing NixOS and want it to boot in UEFI mode, but you are
  #   currently booted in legacy mode
  # - You want to make a drive that will boot regardless of the NVRAM state
  #   of the computer (like a USB "removable" drive)
  # - You simply dislike the idea of depending on NVRAM state to make your
  #   drive bootable
  boot.loader.grub.efiInstallAsRemovable = true;

  # Create a user for external connections for the purposes of Syncoid
  # snapshot transfers.
  users.users.sanoid = {
    # Indicates if the user is a system user or not. This option only has an
    # effect if `uid` is `null`, in which case it determines whether the
    # user's UID is allocated in the range for system users (below 500) or in
    # the range for normal user (starting at 1000). Exactly one of
    # `isNormalUser` and `isSystemUser` must be true.
    isSystemUser = true;
    # If true, the user's shell will be set to `users.defaultUserShell`.
    #
    # This option is necessary to enable SSH login.
    useDefaultShell = true;
    extraGroups = [
      "wheel" # Enable 'sudo' for the user. Necessary for ZFS commands.
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzIn7LY5H1DnrdMXTNdVzpBEMn7WozeCZ8n/1rcTZqT root@lab-ca-kvm-01"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPM+3z4vfZHUaEZPlkQbRiTM9BjL704/aYtX/LruUrIy root@lab-ca-kvm-02"
    ];
  };

  boot.initrd.kernelModules = [
    # Ensure the kernel module for your network card is in the initrd.
    #
    # You can find the relevant module with:
    # $ ls -l /sys/class/net/eno1/device/driver
    #
    # In our case, the kernel module is `igb`.
    "igb"
    # We add the `kvm-intel` kernel module so that libvirt can perform KVM
    # acceleration. On an AMD machine, this would be replaced with the
    # `kvm-amd` module.
    "kvm-intel"
  ];

  services.sanoid = {
    # Enable Sanoid ZFS snapshotting service.
    enable = true;

    datasets = {
      "zroot-0a5dd4/safe" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 10;
        autosnap = true;
        autoprune = true;
        recursive = true;
        processChildrenOnly = true;
      };

      "zpool-fnazxg/safe" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 10;
        autosnap = true;
        autoprune = true;
        recursive = true;
        processChildrenOnly = true;
      };

      "zpool-fnazxg/backup" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 10;
        autosnap = false;
        autoprune = true;
        recursive = true;
      };

      "zpool-fnazxg/backup/lap-ca-nik-01/time-machine" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 10;
        autosnap = true;
        autoprune = true;
      };
    };

    # Extra arguments to pass to sanoid. See
    # https://github.com/jimsalterjrs/sanoid/#sanoid-command-line-options
    # for allowed options.
    extraArgs = [ "--verbose" "--debug" ];
  };

  services.samba.enable = true;
  services.samba.securityType = "user";
  # Disable Samba's nmbd, because we don't want to reply to NetBIOS over IP
  # requests, since all of our clients hardcode the server shares.
  services.samba.enableNmbd = false;
  # Disable Samba's winbindd, which provides a number of services to the Name
  # Service Switch capability found in most modern C libraries, to arbitrary
  # applications via PAM and ntlm_auth and to Samba itself.
  services.samba.enableWinbindd = false;
  services.samba.extraConfig = ''
    # Show the server host name in the printer comment box in print manager
    # and next to the IPC connection in net view.
    server string = lab-ca-nas-01
    # Set the NetBIOS name by which the Samba server is known.
    netbios name = lab-ca-nas-01
    # Allow access to specific Tailscale machines and localhost.
    hosts allow = 100.92.82.97 100.92.246.61 127.0.0.1
    # Deny access to all hosts by default.
    hosts deny = 0.0.0.0/0
    # User logins with a non-existent user are treated as a guest login and
    # mapped into the guest account.
    guest account = guest
    map to guest = bad user
    # Disable netbios support. We don't need to support browsing since all
    # clients hardcode the host and share names.
    disable netbios = yes
    # Clients should only connect using the latest SMB3 protocol (e.g., on
    # clients running Windows 8 and later).
    server min protocol = SMB3_11
    # Disable printer sharing. By default Samba shares printers configured
    # using CUPS.
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes
    show add printer wizard = no
    # Require native SMB transport encryption by default.
    smb encrypt = required
    # Load in modules (order is critical!) and enable AAPL extensions.
    vfs objects = catia fruit streams_xattr
    # Enable Apple's SMB2+ extension.
    fruit:aapl = yes
    # Clean up unused or empty files created by the OS or Samba.
    fruit:wipe_intentionally_left_blank_rfork = yes
    fruit:delete_empty_adfiles = yes
  '';
  services.samba.shares.guest = {
    path = "/guest";
    # Don't require a password to connect to the service. Privileges will be
    # those of the guest account.
    "guest ok" = "yes";
    # Only guest connections to the service are permitted.
    "guest only" = "yes";
    # Users of the service may create and modify files in the service's
    # directory.
    "read only" = "no";
  };
  services.samba.shares.time-machine = {
    path = "/backup/lap-ca-nik-01/time-machine";
    # Hide the share from the list of available shares in a net view and in
    # the browse list.
    browseable = "no";
    "valid users" = "indiv0";
    "write list" = "indiv0";
    "force user" = "indiv0";
    "create mask" = "0600";
    "directory mask" = "0700";
    "fruit:time machine" = "yes";
    # Limits the reported disksize, thus preventing Time Machine from
    # using the whole real disk space for backup. This option takes a
    # number plus an optional unit.
    #
    # IMPORTANT: This is an approximated calculation that only takes into
    # account the contents of Time Machine sparsebundle images. Therefore
    # you MUST NOT use this volume to store other content when using this
    # option, because it would NOT be accounted.
    #
    # NOTE: I've set this to match the ZFS quota for the dataset.
    "fruit:time machine max size" = "2T";
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;
  # Allow Samba clients to connect through the firewall.
  networking.firewall.allowedTCPPorts = [ 445 139 ];

  # Create a user which anonymous Samba users will be mapped to.
  users.users.guest.uid = 18277;
}
