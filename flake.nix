{
  description = "Sync tom7misc";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        name = "sync-tom7misc";

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.subversion
            pkgs.gitSVN
          ];
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
