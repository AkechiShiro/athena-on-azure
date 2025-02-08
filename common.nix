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
  diskSize = 15*1024;
  # These variable names are used by Aegis backend
  version = "unstable"; # or 24.11
  username = "athena";
  hashed = "$6$zjvJDfGSC93t8SIW$AHhNB.vDDPMoiZEG3Mv6UYvgUY6eya2UY5E2XA1lF7mOg6nHXUaaBmJYAMMQhvQcA54HJSLdkJ/zdy8UKX3xL1";
  hashedRoot = "$6$zjvJDfGSC93t8SIW$AHhNB.vDDPMoiZEG3Mv6UYvgUY6eya2UY5E2XA1lF7mOg6nHXUaaBmJYAMMQhvQcA54HJSLdkJ/zdy8UKX3xL1";
  hostname = "athenaos";
  theme = "temple";
  desktop = "gnome";
  dmanager = "gdm";
  mainShell = "fish";
  terminal = "kitty";
  browser = "firefox";
  bootloader = if builtins.pathExists "/sys/firmware/efi" then "systemd" else "grub";
  hm-version = if version == "unstable" then "master" else "release-${version}"; # "master" or "release-24.11"; # Correspond to home-manager GitHub branches
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
    ./.
    "${modulesPath}/virtualisation/azure-image.nix"
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
    # Important for Azure
    useNetworkd = true;
    hostName = "${hostname}";
    enableIPv6 = true;
  };

  # Enable zram swap
  zramSwap.enable = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  nix.settings.trusted-users = [ "root" "@wheel" ];
  # Azure image
  services.waagent = { 
    enable = true;
    # Doesn't work properly at the moment
    settings = {
      Provisioning.Enable = true;
      Agent = "waagent";
      AutoUpdate.Enable = true;
    };
  };
  virtualisation.diskSize = diskSize;
  virtualisation.azureImage.vmGeneration = "v2";
  virtualisation.azure.acceleratedNetworking = true;

  image.fileName = "disk.vhd";

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
    };
    flatpak.enable = false;

    # Let Waagent provision ssh key and username from Azure API during VM creation

    xrdp = { 
      enable = true;
      # gnome: gnome-session
      # kde Plasma : start-plasmawayland doesn't work
      # extend with mkIf config
      defaultWindowManager = "gnome-session";
      openFirewall = true;
    };
  };

  systemd.services.cloud-config.serviceConfig = {
    Restart = "on-failure";
  };

  security.sudo.wheelNeedsPassword = false;
  # Workaround needed for runScriptShell on Azure Portal
  programs.nix-ld.enable = true;

  cyber = {
    enable = false;
    role = "student";
  };
}
