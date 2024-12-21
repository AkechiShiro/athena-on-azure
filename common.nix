# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ username }:
{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  # These variable names are used by Aegis backend
  version = "unstable"; # or 24.05
  username = "athena";
  hashed = "$6$JCSoBNUqffP/wMhL$8BB2qj58olM/InfvtmZA4Wi84j4MFvxCQwGptG849dind0BJ5jEd3orqpPZTB0bPZeyyFRAURCC3IRKYRfaMd.";
  hashedRoot = "$6$JCSoBNUqffP/wMhL$8BB2qj58olM/InfvtmZA4Wi84j4MFvxCQwGptG849dind0BJ5jEd3orqpPZTB0bPZeyyFRAURCC3IRKYRfaMd.";
  hostname = "athenaos";
  theme = "temple";
  desktop = "gnome";
  dmanager = "gdm";
  mainShell = "fish";
  terminal = "kitty";
  browser = "firefox";
  bootloader = if builtins.pathExists "/sys/firmware/efi" then "systemd" else "grub";
  hm-version = if version == "unstable" then "master" else "release-" version; # "master" or "release-24.05"; # Correspond to home-manager GitHub branches
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/${hm-version}.tar.gz";
  openssh-key = builtins.readFile /home/kenshin/.ssh/id_ed25519_dev.pub;
in
{
  imports = [
    # Include the results of the hardware scan.
    {
      athena = {
        inherit
          bootloader
          terminal
          theme
          mainShell
          browser
          ;
        enable = true;
        homeManagerUser = username;
        baseConfiguration = true;
        baseSoftware = true;
        baseLocale = true;
        desktopManager = desktop;
        displayManager = dmanager;
      };
    }
    (import "${home-manager}/nixos")
    #./.
    "${modulesPath}/virtualisation/azure-common.nix"
  ];

  users = lib.mkIf config.athena.enable {
    mutableUsers = false;
    extraUsers.root.hashedPassword = "${hashedRoot}";
    users.${config.athena.homeManagerUser} = {
      shell = pkgs.${config.athena.mainShell};
      isNormalUser = true;
      hashedPassword = "${hashed}";
      extraGroups = [
        "wheel"
        "input"
        "video"
        "render"
      ];
      openssh.authorizedKeys.keys = [ openssh-key ];
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.growPartition = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    networkmanager.enable = lib.mkForce false;
    useDHCP = false;
    # Important for Azure
    useNetworkd = true;
    hostName = "${hostname}";
    enableIPv6 = false;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  #virtualisation.azure.agent.enable = true;
  # Azure image
  virtualisation.diskSize = 16 * 1024;
  virtualisation.azureImage.vmGeneration = "v2";
  virtualisation.azure.acceleratedNetworking = true;

  image.fileName = "nixos.vhd";

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
    };
    flatpak.enable = false;
    cloud-init.network.enable = true;
    xrdp { 
      defaultWindowManager = "gnome-session";
      openFirewall = true;
    };
  };
  systemd.services.cloud-config.serviceConfig = {
    Restart = "on-failure";
  };

  security.sudo.wheelNeedsPassword = false;

  cyber = {
    enable = false;
    role = "student";
  };
}
