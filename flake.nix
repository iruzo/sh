{
  description = "iruzo's shells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs, ... } @ inputs: let
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    # formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      pkgs.alejandra);

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      dockerCompat = pkgs.runCommandNoCC "docker-podman-compat" {} ''
        mkdir -p $out/bin
        ln -s ${pkgs.podman}/bin/podman $out/bin/docker
      '';
      devops_shell = import ./shells/devops.nix { inherit pkgs; inherit dockerCompat; };
      aws_shell = import ./shells/aws.nix { inherit pkgs; inherit dockerCompat; };
    in rec {
      # default = devops;
      devops = devops_shell;
      aws = aws_shell;
    });
  };
}
