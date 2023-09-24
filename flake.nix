{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = inputs:
    with inputs; let
        pkgs = import nixpkgs {
            system = "x86_64-linux";
        };
    in {
      nixosModules = rec {
        default = narrowlink;
        narrowlink = import ./modules/narrowlink;
      };
      checks.x86_64-linux.default = import ./tests {inherit self pkgs;};
    };
}
