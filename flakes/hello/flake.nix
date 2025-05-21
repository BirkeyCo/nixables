{
  description = "Nix Flake for hello";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation {
      name = "hello";
      version = "0.1.0";

      # src points to the directory where we've written files
      src = ./src_files;

      installPhase = ''
        mkdir -p $out/bin
            cp -r bin/hello $out/bin/
            chmod +x $out/bin/hello
      '';

      # Ensures that tools like `cp` and `chmod` are available in the build environment
      nativeBuildInputs = [ nixpkgs.legacyPackages.x86_64-linux.coreutils ];
    };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
  };
}
