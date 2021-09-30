# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B8C7-030D";
    fsType = "vfat";
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-uuid/B8E8-040F";
    fsType = "vfat";
  };

  fileSystems."/nix" = {
    device = "zroot-3z8b5j/local/nix";
    fsType = "zfs";
  };

  fileSystems."/local/storage" = {
    device = "zroot-3z8b5j/local/storage";
    fsType = "zfs";
  };

  fileSystems."/persist" = {
    device = "zroot-3z8b5j/safe/persist";
    fsType = "zfs";
  };

  fileSystems."/storage" = {
    device = "zroot-3z8b5j/safe/storage";
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
    device = "zroot-3z8b5j/local/docker-root";
    fsType = "zfs";
  };

  fileSystems."/var/lib/docker/volumes" = {
    device = "zroot-3z8b5j/safe/docker-volumes";
    fsType = "zfs";
  };

  fileSystems."/root/.ssh" = {
    device = "/persist/root/.ssh";
    fsType = "none";
    options = [ "bind" ];
  };

  swapDevices = [ ];

  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
