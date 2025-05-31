{
  description = "Development environment for Ruby-to-Nix Flake Generator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Define a list of supported systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper function to generate a dev shell for a given system
      mkDevShellForSystem = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
          name = "ruby-nix-dev-env-${system}";

          packages = [
            pkgs.ruby       # For running Ruby scripts
            pkgs.bash       # For general shell scripting
            pkgs.coreutils  # For basic utilities

            # Attempt to add Minitest from rubyPackages.
            # The exact attribute might vary slightly based on Nixpkgs version or Ruby version.
            # Common names are minitest, rubygem-minitest.
            # We'll try pkgs.rubyPackages.minitest first.
            # If this specific attribute doesn't exist in some nixpkgs versions,
            # a user might need to adjust it or use bundler.
            # For now, we assume a common naming.
            (pkgs.rubyPackages.minitest or pkgs.rubygems.minitest or pkgs.minitest)
            # pkgs.bundler # Could be added if Gemfile/Bundler is used
          ];

          shellHook = ''
            echo "Entered Ruby Nix Flake development environment for ${system}."
            echo "Ruby version: $(ruby --version)"
            echo "Minitest should be available from Nixpkgs."
          '';
        };

    in
    {
      # Generate devShells for all supported systems
      devShells = nixpkgs.lib.genAttrs supportedSystems (system: mkDevShellForSystem system);

      # Add a default devShell that attempts to use the host system's shell
      # This is a common convenience, though `nix develop .#` or `nix develop .#<system>` is more explicit.
      # For simplicity, we can point `devShells.default` to one of the common ones,
      # or let the user choose explicitly if their system is not x86_64-linux.
      # Nix typically tries to infer the current system when just `nix develop` is used.
      # Let's ensure `devShells.default` points to a sensible default if needed,
      # but `nixpkgs.lib.genAttrs` for `devShells` is often enough.
      # For wider compatibility, we can set a default explicitly for common cases.
      devShells.default = self.devShells.x86_64-linux.default; # Or let Nix infer
    };
}
