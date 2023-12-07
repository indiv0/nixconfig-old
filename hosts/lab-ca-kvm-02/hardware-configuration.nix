# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=16G" "mode=755" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1054-122B";
    fsType = "vfat";
  };

  #fileSystems."/boot-fallback" = {
  #  device = "/dev/disk/by-uuid/10AC-0764";
  #  fsType = "vfat";
  #};

  fileSystems."/nix" = {
    device = "zroot-mutcso/local/nix";
    fsType = "zfs";
  };

  # CLEARED BUT NOT SCRUBBED
  #fileSystems."/local/storage" = {
  #  device = "zroot-mutcso/local/storage";
  #  fsType = "zfs";
  #};

  fileSystems."/persist" = {
    device = "zroot-mutcso/safe/persist";
    fsType = "zfs";
  };

  fileSystems."/storage" = {
    device = "zpool-xkui0j/safe/storage";
    fsType = "zfs";
  };

  fileSystems."/var/lib/tailscale" = {
    device = "/persist/var/lib/tailscale";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/etc/postfix.local" = {
    device = "/persist/etc/postfix.local";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/cache/private/sanoid" = {
    device = "/persist/var/cache/private/sanoid";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/cache/mlocate" = {
    device = "/persist/var/cache/mlocate";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/docker" = {
    device = "zroot-mutcso/docker-root";
    fsType = "zfs";
  };

  fileSystems."/var/lib/docker/volumes" = {
    device = "zroot-mutcso/docker-volumes";
    fsType = "zfs";
  };

  #fileSystems."/zroot-mutcso/safe/storage" = {
  #  device = "zroot-mutcso/safe/storage";
  #  fsType = "zfs";
  #};

  #fileSystems."/var/lib/libvirt/images" = {
  #  device = "zroot-mutcso/safe/images";
  #  fsType = "zfs";
  #};

  fileSystems."/root/.ssh" = {
    device = "/persist/root/.ssh";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/home/indiv0" = {
    device = "/persist/home/indiv0";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/syncoid/.ssh" = {
    device = "/persist/home/syncoid/.ssh";
    fsType = "none";
    options = [ "bind" ];
  };

  swapDevices = [ ];



  ### NFS ###

  fileSystems."/export/storage" = {
    device = "/storage";
    options = [ "bind" ];
  };
}
