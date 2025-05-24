require 'fileutils'
require_relative '../lib/recipe_dsl' # Adjust path as necessary

class FlakeGenerator
  def initialize(recipe_path)
    unless File.exist?(recipe_path)
      raise ArgumentError, "Recipe file not found: #{recipe_path}"
    end
    @recipe = RecipeDSL.load_recipe(recipe_path)
    @package_name = @recipe.name
    @package_version = @recipe.version
    @output_commands = @recipe.output_commands

    @flake_output_dir = File.join('flakes', @package_name)
    # Source files will be placed here, to be referenced by flake.nix
    @source_build_dir = File.join(@flake_output_dir, 'src_files')
  end

  def generate
    prepare_source_files
    flake_content = generate_flake_nix_content
    
    FileUtils.mkdir_p(@flake_output_dir)
    output_path = File.join(@flake_output_dir, 'flake.nix')
    File.write(output_path, flake_content)

    puts "Generated Nix Flake for #{@package_name} at #{output_path}"
    puts "Source files prepared in #{@source_build_dir}"
  end

  private

  def prepare_source_files
    FileUtils.rm_rf(@source_build_dir) # Clean previous build
    FileUtils.mkdir_p(@source_build_dir)

    @output_commands.each do |cmd_obj|
      case cmd_obj[:command]
      when :write_file
        full_path = File.join(@source_build_dir, cmd_obj[:path])
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, cmd_obj[:content])
        puts "Written file: #{full_path}"
      # :make_executable is handled in installPhase, but we could pre-check paths here
      when :make_executable
        # Ensure the file to be made executable was previously written
        target_file = File.join(@source_build_dir, cmd_obj[:path])
        unless File.exist?(target_file)
          raise "Error: make_executable called on non-existent file: #{cmd_obj[:path]}"
        end
        # Actual chmod +x happens in the Nix environment during build
        puts "Will make executable in Nix: #{cmd_obj[:path]}"
      end
    end
  end

  def generate_install_phase
    install_cmds = ["mkdir -p $out/bin"] # Basic structure
    chmod_cmds = []

    @output_commands.each do |cmd_obj|
      case cmd_obj[:command]
      when :write_file
        # We need to copy the file from src to $out
        # Assuming files under 'bin/' go to '$out/bin/', other structures might need more logic
        relative_path = cmd_obj[:path]
        if relative_path.start_with?("bin/")
          install_cmds << "cp -r #{relative_path} $out/bin/"
        else
          # For now, just copy to top of $out, this can be expanded
          install_cmds << "cp -r #{relative_path} $out/"
        end
      when :make_executable
        # The chmod needs to happen on the file *in the $out* directory
        relative_path = cmd_obj[:path]
        if relative_path.start_with?("bin/")
          chmod_cmds << "chmod +x $out/#{relative_path}"
        else
            # For now, assumes it's at top of $out
          chmod_cmds << "chmod +x $out/#{File.basename(relative_path)}"
        end
      end
    end
    
    (install_cmds + chmod_cmds).join("\n            ")
  end

  def generate_flake_nix_content
    install_phase_script = generate_install_phase

    <<~NIX
      {
        description = "Nix Flake for #{@package_name}";

        inputs = {
          nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        };

        outputs = { self, nixpkgs }: {
          packages.x86_64-linux.#{@package_name} = nixpkgs.legacyPackages.x86_64-linux.stdenv.mkDerivation {
            name = "#{@package_name}";
            version = "#{@package_version}";

            # src points to the directory where we've written files
            src = ./src_files;

            installPhase = ''
              #{install_phase_script}
            '';

            # Ensures that tools like `cp` and `chmod` are available in the build environment
            nativeBuildInputs = [ nixpkgs.legacyPackages.x86_64-linux.coreutils ];
          };

          defaultPackage.x86_64-linux = self.packages.x86_64-linux.#{@package_name};
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
    generator = FlakeGenerator.new(recipe_file_path)
    generator.generate
  rescue StandardError => e # Catch more general errors
    puts "Error: #{e.message}"
    puts e.backtrace
    exit 1
  end
end
