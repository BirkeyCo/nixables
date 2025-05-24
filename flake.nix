{
  description = "Development environment for Ruby-to-Nix Flake Generator";

  inputs = {
    # nix dsl fns useful for writing flakes
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    # Pins state of the packages to a specific commit sha
    pinnedPkgs.url = "github:NixOS/nixpkgs/c46290747b2aaf090f48a478270feb858837bf11";
  };

  # required attribute
  outputs = { self, flake-utils, pinnedPkgs }@inputs :
  flake-utils.lib.eachDefaultSystem (system:
  let pinnedSysPkgs = inputs.pinnedPkgs.legacyPackages.${system};
  in
  {
    devShells.default = pinnedSysPkgs.mkShell {
      packages = [
        pinnedSysPkgs.ruby
        pinnedSysPkgs.rubyPackages.minitest
      ];

      # commands to run in the development interactive shell
      shellHook = ''
         echo ruby tests/test_hello_flake.rb
      '';
    };
    packages = {
      docker = pinnedSysPkgs.dockerTools.buildLayeredImage {
        name = "Development environment for Ruby-to-Nix Flake Generator Docker img";
        tag = "latest";
        contents = [pinnedSysPkgs.ruby pinnedSysPkgs.rubyPackages.minitest];
      };
    };
  });
}
