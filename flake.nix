{
  description = "Sync tom7misc";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
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
        name = "rudelblinken-rs";

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
