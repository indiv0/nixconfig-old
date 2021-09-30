# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:
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

  networking.hostName = "lab-ca-kvm-02";

  # Set NIX_PATH for NixOS config and nixpkgs.
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/etc/nixos/hosts/lab-ca-kvm-02/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure the system to boot with grub and manage /boot automatically.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";

  # Mirror all UEFI files, kernels, grub menus, and other things needed to
  # to the other drive.
  boot.loader.grub.mirroredBoots = [
    {
      devices = [ "/dev/disk/by-uuid/10AC-0764" ];
      path = "/boot-fallback";
    }
  ];

  # Configure the system to support ZFS.
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "92734162";

  # Request encryption credentials to unlock the ZFS dataset at root.
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
  networking.defaultGateway.interface = "br0";
  networking.bridges.br0.interfaces = [ "enp6s0" ];
  networking.interfaces.br0.macAddress = "18:c0:4d:87:d6:af";
  networking.interfaces.br0.ipv4.addresses = [{
    address = "172.30.194.6";
    prefixLength = 24;
  }];
  # Enable the systemd DNS resolver daemon.
  services.resolved.enable = true;
  services.resolved.domains = [ "olympus.hax.rs" ];

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
  my.user.extraGroups = [
    "docker" # Manage Docker as a non-root user.
    "libvirtd" # Permissions to manage libvirt containers.
  ];

  # Define my user account for deployments.
  my.deploy-user.enable = true;

  # Enable ZFS trim, snapshot, scrub, and ZED email alerts.
  my.zfs.enable = true;

  # Enable periodic smartd monitoring with email notifications.
  my.smartd.enable = true;

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
      zpool import zpool-xkui0j 
      echo "zfs load-key -a; killall zfs" >> /root/.profile
    '';
  };

  # Install useful packages globally.
  environment.systemPackages = with pkgs; [
    tree
    vim
  ];

  # Use systemd's tmpfiles.d rules to create a symlink from
  # `/var/lib/libvirt/images` and `/var/lib/libvirt/qemu` to my persisted
  # directory.
  systemd.tmpfiles.rules = [
    "L /var/lib/libvirt/qemu - - - - /persist/var/lib/libvirt/qemu"
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

  # Bind the `vfio-pci` driver to any devices (e.g., GPUs) that we wish to
  # pass to VMs.
  boot.initrd.availableKernelModules = [ "vfio-pci" ];
  #boot.initrd.preDeviceCommands = ''
  #  DEVS="0000:0b:00.0 0000:0b:00.1"
  #  for DEV in $DEVS; do
  #    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #  done
  #  modprobe -i vfio-pci
  #'';
  #boot.postBootCommands = ''
  #  DEVS="0000:0b:00.0 0000:0b:00.1"
  #  for DEV in $DEVS; do
  #    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #  done
  #  modprobe -i vfio-pci
  #'';

  # Update to the latest linux kernel instead of the default LTS kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "kvm.ignore_msrs=1"
    "kvm.report_ignored_msrs=0"
    # Configure the kernel to assign a static IP in the initrd.
    # This is necessary as using DHCP can result in a race condition where
    # udhcpc fails because the interface isn't ready yet.
    #
    # ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:
    #   <autoconf>:<dns0-ip>:<dns1-ip>:<ntp0-ip>
    "ip=172.30.194.6::172.30.194.1:255.255.255.0:lab-ca-kvm-02:enp6s0"
    # Enable IOMMU groups. Use "intel_iommu=on" on an Intel system.
    "amd_iommu=on"
    # Prevent Linux from touching devices which cannot be passed through.
    "iommu=pt"
    # Alleviate hotplugging issues.
    "pci=realloc"
    # Block the usage of the EFI framebuffer on boot.
    "video=efifb:off"
    # Bind devices to vfio-pci by PCI IDs.
    "vfio-pci.ids=10de:2204,10de:1aef"
  ];

  # Blacklist any NVIDIA drivers from binding to the GPU.
  boot.blacklistedKernelModules = [ "nvidia" "nouveau" "nvidiafb" ];
  boot.initrd.kernelModules = [
    # Ensure the kernel module for your network card is in the initrd.
    #
    # You can find the relevant module with:
    # $ ls -l /sys/class/net/enp0s31f6/device/driver
    #
    # In our case, the kernel module is `igb`.
    "igb"
    # We add the `kvm-amd` kernel module so that libvirt can perform KVM
    # acceleration. On an Intel machine, this would be replaced with the
    # `kvm-intel` module.
    "kvm-amd"
  ];
  # Add the extra kernel modules that are needed for VFIO.
  boot.kernelModules = [ "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];

  # Enable libvirtd, a daemon that manages virtual machines.
  # Users in the "libvirtd" group can interact with the daemon (e.g. to
  # start or stop VMs) using the `virsh` command line tool, among others.
  virtualisation.libvirtd.enable = true;
  # Specifies the action to be done to / on the guests when the host boots.
  # The "start" option starts all guests that were running prior to shutdown
  # regardless of their autostart settings. The "ignore" option will not
  # start the formerly running guest on boot. However, any guest marked as
  # autostart will still be automatically started by libvirtd.
  virtualisation.libvirtd.onBoot = "ignore";

  virtualisation.docker = {
    # Enable Docker as a container daemon.
    enable = true;
    # Configure Docker to use ZFS as the storage driver.
    # By default, Docker will automatically determine the appropriate driver
    # to use, but just to be safe we force it to use ZFS.
    storageDriver = "zfs";
    # Periodically prune Docker resources. A systemd timer will run
    # `docker system prune -f`. By default, the timer will run weekly.
    autoPrune.enable = true;
  };

  # Fix conflict between Docker and KVM `iptables` rules.
  networking.firewall.extraCommands = ''
    iptables -I FORWARD -i br0 -o br0 -j ACCEPT
  '';

  # Configure the governor used to regulate the frequency of the available
  # CPUs. By default, the kernel configures the performance governor,
  # although this may be overwritten in your `hardware-configuration.nix`
  # file. By default, Nix configures the ondemand governor.
  powerManagement.cpuFreqGovernor = "performance";

  services.sanoid = {
    # Enable Sanoid ZFS snapshotting service.
    enable = true;

    datasets = {
      "zpool-xkui0j/safe" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 5;
        autosnap = true;
        autoprune = true;
        recursive = true;
        processChildrenOnly = true;
      };

      "zroot-mutcso/safe" = {
        hourly = 24;
        daily = 30;
        monthly = 12;
        yearly = 5;
        autosnap = true;
        autoprune = true;
        recursive = true;
        processChildrenOnly = true;
      };
    };

    # Extra arguments to pass to sanoid. See
    # https://github.com/jimsalterjrs/sanoid/#sanoid-command-line-options
    # for allowed options.
    extraArgs = [ "--verbose" "--debug" ];
  };

  services.syncoid =
    let
      backupbox = "100.85.82.78";
      mkRemoteSync = dest: {
        recursive = true;
        target = "sanoid@${backupbox}:zpool-fnazxg/backup/${dest}";
      };
    in
    {
      enable = true;
      sshKey = "/root/.ssh/id_ed25519";
      #commonArgs = [ "--no-stream" ];
      commands = {
        # Remote syncs.
        "zpool-xkui0j/safe" = mkRemoteSync "zpool-xkui0j/safe";
        "zroot-mutcso/safe" = mkRemoteSync "zroot-mutcso/safe";
      };
    };

  # Additional groups to be created automatically by the system.
  #
  # Default: `{}`
  users.groups = {
    # Define an `app` group to match the one that exists for GID 1000 in the
    # `virt-manager` container. This group must exist for `virt-manager` to
    # connect to `qemu:///system` through a mounted socket.
    app.gid = 1000;
  };
}
