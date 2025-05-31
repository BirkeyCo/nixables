require 'fileutils'
require 'tmpdir' # For potentially creating isolated loading contexts if needed

# Load the Formula DSL.
# This path needs to be robust. Assuming generator is run from project root.
require_relative '../lib/formula_dsl'

class FlakeGenerator
  def initialize(recipe_path)
    unless File.exist?(recipe_path)
      raise ArgumentError, "Recipe file not found: #{recipe_path}"
    end
    @recipe_path = recipe_path
    @formula_instance = load_and_instantiate_formula

    @package_name = @formula_instance.name
    @package_version = @formula_instance.version
    @install_commands = @formula_instance.install_commands
  end

  def load_and_instantiate_formula
    # Load the recipe file. This will define the formula class.
    # Using `load` executes the file in a an anonymous module (sandbox-like)
    # but makes it harder to get the class out.
    # `require_relative` would also work if path is correct and only loads once.
    # For simplicity, `load` is used here, but might need refinement for complex scenarios.

    # We need to find the class defined in the recipe that inherits from Formula.
    # This is a bit hacky. A better way would be for recipes to register themselves.
    # For now, scan new classes after loading.

    existing_classes = ObjectSpace.each_object(Class).to_a

    # Load the script. The class definition happens here.
    # Using `load` ensures it's re-evaluated if changed, good for dev.
    load @recipe_path

    new_classes = ObjectSpace.each_object(Class).to_a - existing_classes

    formula_class = new_classes.find do |klass|
      klass.ancestors.include?(HomebrewStyleDSL::Formula) && klass != HomebrewStyleDSL::Formula
    end

    unless formula_class
      raise "No class inheriting from HomebrewStyleDSL::Formula found in #{@recipe_path}"
    end

    instance = formula_class.new
    instance.install # This call is crucial to populate @install_commands by executing user's install block
    instance
  end

  def generate
    @flake_output_dir = File.join('flakes', @package_name)
    @empty_src_dir = File.join(@flake_output_dir, 'empty_src')

    FileUtils.mkdir_p(@flake_output_dir)
    FileUtils.mkdir_p(@empty_src_dir) # Create empty src directory

    flake_content = generate_flake_nix_content
    output_path = File.join(@flake_output_dir, 'flake.nix')
    File.write(output_path, flake_content)

    puts "Generated Nix Flake for #{@package_name} at #{output_path}"
    puts "Empty source directory created at #{@empty_src_dir}"
  end

  private

  def generate_install_phase
    # Replace the placeholder prefix and join commands
    @install_commands.map { |cmd| cmd.gsub("__PREFIX__", "$out") }.join("\n      ")
  end

  def generate_flake_nix_content
    install_phase_script = generate_install_phase

    # Note: For a formula that specifies a URL, `src` would be different.
    # For generated content like hello-echo, src is a placeholder.
    <<~NIX
      {
        description = "Nix Flake for #{@package_name} (generated from Homebrew-style formula)";

        inputs = {
          nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        };

        outputs = { self, nixpkgs }:
        let
          system = "x86_64-linux"; # Or make this configurable
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages.${system}.#{@package_name} = pkgs.stdenv.mkDerivation {
            name = "#{@package_name}";
            version = "#{@package_version}";

            # src is a placeholder for recipes that generate their own content
            src = ./empty_src;

            # buildInputs would come from formula.depends_on if implemented
            # nativeBuildInputs = [ pkgs.some_build_tool ];

            installPhase = ''
              #{install_phase_script}
            '';

            # Ensure coreutils for basic commands like mkdir, echo, chmod if not part of stdenv
            nativeBuildInputs = [ pkgs.coreutils pkgs.bash ]; # bash for `sh -c` if used
          };

          defaultPackage.${system} = self.packages.${system}.#{@package_name};
          defaultPackage = self.packages.${system}.#{@package_name}; # for convenience
        };
      }
    NIX
  end
end

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby generator/generate_flake.rb <path_to_recipe.rb>"
    exit 1
  end
  recipe_file_path = ARGV[0]
  begin
    # Make sure the DSL file is loaded relative to this script's location if not already.
    # This is important if script is called from a different directory.
    require_relative File.join(__dir__, '../lib/formula_dsl.rb')

    generator = FlakeGenerator.new(recipe_file_path)
    generator.generate
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts e.backtrace
    exit 1
  end
end
