module RecipeDSL
  def self.load_recipe(filepath)
    Recipe.new.instance_eval(File.read(filepath), filepath)
  end

  class Recipe
    attr_reader :name, :version, :output_commands

    def initialize
      @output_commands = []
    end

    def package(name, &block)
      @name = name
      # We might add more package-level settings here in the future
      instance_eval(&block) if block_given?
      self # Return self to allow chaining or capturing the recipe object
    end

    def set_version(version_string) # Renamed from 'version'
      @version = version_string
    end

    # This block will capture commands for the generator to process
    def output(&block)
      # For now, we'll just execute the block in the context of self.
      # The methods inside this block will add to @output_commands.
      instance_eval(&block)
    end

    def write_file(path, content)
      @output_commands << { command: :write_file, path: path, content: content }
    end

    def make_executable(path)
      @output_commands << { command: :make_executable, path: path }
    end
  end
end

# Example of how it might be used (for testing the DSL itself, not for the main generator yet):
# recipe_data = RecipeDSL.load_recipe('path/to/your/recipe.rb')
# puts "Package Name: #{recipe_data.name}"
# puts "Version: #{recipe_data.version}"
# puts "Output Commands: #{recipe_data.output_commands}"
