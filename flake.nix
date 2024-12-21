{
  inputs.nixos.url = "github:codgician/nixpkgs/fix-azure-modules";


  outputs = { nixos, ... }:
    let
      username = "athena-azure";
      desktop = "gnome";
      dmanager = "gdm";
      system = "x86_64-linux";
      pkgs = import nixos { inherit system; config.allowUnfree = true; };
    in
    {
       "runtime" = mkSystem [
          "/etc/nixos/hardware-configuration.nix"
          (import ./common.nix {inherit username;})
          home-manager.nixosModules.home-manager
          ./.
          {
          athena = {
            inherit bootloader terminal theme mainShell browser;
            enable = true;
            baseConfiguration = true;
            baseSoftware = true;
            baseLocale = true;
            homeManagerUser = username;
            desktopManager = desktop;
            displayManager = dmanager;
          };
          }
        ];

      packages.${system}.azure-image =
        let
          img = nixos.lib.nixosSystem {
            inherit pkgs system;

            modules = [
              ./image.nix
	            ./.
              (import ./common.nix { inherit username; })
            ];
          };
        in
        img.config.system.build.azureImage;
      packages.${system}.azure-image =
        let
          img = nixos.lib.nixosSystem {
            inherit pkgs system;

            modules = [
              ./image.nix
	            ./.
              (import ./common.nix { inherit username; })
            ];
          };
        in
        img.config.system.build.azureImage;

      devShells.${system}.default =
        with pkgs;
        mkShell
          {
            buildInputs = with pkgs; [
              azure-cli
              azure-storage-azcopy
              jq
            ];
          };

      devShells."aarch64-darwin".default =
        let
          pkgs = import nixos { system = "aarch64-darwin"; };
        in
        with pkgs;
        pkgs.mkShell
          {
            buildinputs = with pkgs; [
              azure-cli
              azure-storage-azcopy
              jq
            ];
          };
    };
}

