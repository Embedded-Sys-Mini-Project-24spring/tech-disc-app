{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShell = pkgs.mkShell rec {
        nativeBuildInputs = with pkgs; []; 
        propagatedBuildInputs = with pkgs; [
            node2nix  
            nodejs
        ];
         
    shellHook = ''
    '';
      };
    }
  );
}
