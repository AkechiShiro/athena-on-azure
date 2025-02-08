{
  inputs.nixos.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { nixos, ... }:
    let
      username = "athena";
      system = "x86_64-linux";
      pkgs = import nixos { inherit system; };
    in
    {
      packages.${system}.azure-image =
        let
          img = nixos.lib.nixosSystem {
            inherit pkgs system;

            modules = [
              ./image.nix
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
