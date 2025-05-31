# lib/formula_dsl.rb

module HomebrewStyleDSL
  class Formula
    # Class instance variables to store metadata
    @desc_val = ""
    @homepage_val = ""
    @version_val = ""

    # Array to store recorded system commands
    attr_reader :install_commands
    attr_reader :name # Will be derived from the subclass name

    # --- Class methods for metadata ---
    def self.desc(val)
      @desc_val = val
    end

    def self.homepage(val)
      @homepage_val = val
    end

    def self.version(val)
      @version_val = val
    end

    # --- Getter methods for class instance variables (for the instance to access them) ---
    def desc
      self.class.instance_variable_get(:@desc_val) || ""
    end

    def homepage
      self.class.instance_variable_get(:@homepage_val) || ""
    end

    def version
      self.class.instance_variable_get(:@version_val) || ""
    end

    # --- Instance methods ---
    def initialize
      @install_commands = []
      @name = self.class.name.split('::').last # Get the class name without modules
                                               # This will be used as the package name by the generator
      # The actual install block will be defined in the subclass
    end

    # This method will be called by the subclass's install method.
    # It provides the context for `system` calls.
    def define_install_steps(&block)
      # Clear any previous commands if define_install_steps is called multiple times (shouldn't happen in normal use)
      @install_commands.clear
      # Execute the block in the context of this instance,
      # so `system` calls within the block resolve to `self.system`.
      self.instance_eval(&block)
    end

    # The `install` method that subclasses will override/define.
    # Subclasses should call `super` or `define_install_steps` with their block.
    def install(&block)
      if block_given?
        define_install_steps(&block)
      else
        # This case allows subclasses to define `install do ... end`
        # which effectively calls this method with a block.
        # However, Ruby doesn't automatically pass the block this way.
        # The subclass itself needs to capture its block and pass it.
        # A more common pattern for subclasses would be:
        # def install
        #   super do
        #     system "echo", "hello"
        #   end
        # end
        # For simplicity in the subclass, we'll rely on the generator to call `formula_instance.install(&captured_block)`
        # if we can make the `install do ... end` syntax work directly.
        # For now, let's assume the generator will extract the install block and pass it.
        # Or, we make it the subclass's responsibility to call `define_install_steps`.
        # Let's go with the latter for more explicit control in the subclass.
        # So, subclasses will look like:
        #   def install
        #     define_install_steps do
        #       system "cmd1"
        #     end
        #   end
        # This makes the `install` method here a bit redundant as a simple definition.
        # The real work is in `define_install_steps`.
      end
    end

    # --- Path helpers ---
    # These will be replaced by the generator with actual Nix paths (e.g., $out)
    def prefix
      "__PREFIX__" # Placeholder for $out
    end

    def bin
      "#{prefix}/bin" # Corrected interpolation
    end

    def lib
      "#{prefix}/lib" # Corrected interpolation
    end

    def man
      "#{prefix}/share/man" # Corrected interpolation
    end

    # --- System command recording ---
    def system(*args)
      # Convert all arguments to string, quote if necessary
      cmd_parts = args.map do |arg|
        if arg.is_a?(String) && arg.include?(" ")
          "'#{arg}'" # Simple quoting for args with spaces
        else
          arg.to_s
        end
      end
      @install_commands << cmd_parts.join(" ")
      puts "Recorded system command: #{cmd_parts.join(" ")}" # For debugging
      true # Mimic behavior of Kernel#system returning true on success
    end

    # --- Utility for loading ---
    # This is a simplified loader. A real one would be more robust.
    def self.load_formula(path)
      content = File.read(path)
      # Dynamically find the Formula subclass in the file
      # This is a bit naive; a better way might be needed for complex files
      # or files with multiple classes.
      class_name_match = content.match(/class\s+([A-Za-z0-9_]+)\s*<\s*Formula/)
      unless class_name_match
        raise "No class inheriting from Formula found in #{path}"
      end
      class_name = class_name_match[1]

      # Evaluate the file content. This will define the class.
      # We need a binding or module context if we want to isolate it.
      # For now, we'll eval it globally, which is not ideal for safety.
      # A better approach would be to use `Kernel.load` or `require`
      # if the file structure allows, then find the class.
      # Or use `Module.new.module_eval(content, path)` to sandbox.

      # For the current structure, where the file defines a class,
      # we need to ensure the class is defined and then we can instantiate it.
      # `require_relative` or `load` is better than `eval` if possible.
      # Let's assume for now the generator will handle loading the file
      # such that the class becomes defined.

      # This method is becoming more of a conceptual placeholder for what the generator needs to do.
      # The generator will likely:
      # 1. `load` or `require` the .rb file.
      # 2. Find the Formula subclass (e.g., by looking at ObjectSpace.each_object(Class))
      # 3. Instantiate it: `FoundClass.new`

      # For now, let's make this method return the first found subclass of Formula
      # after loading the file. This assumes the file is loaded by the caller.
      # This part will need refinement in the generator step.

      # Let's defer the actual loading mechanism to the generator.
      # This DSL file just defines the Formula class.
      # The generator will be responsible for loading the recipe and finding the class.
      Object.const_get(class_name).new if class_name
    rescue NameError
      raise "Class #{class_name} not found after evaluating #{path}. Ensure the class is defined correctly."
    end
  end
end

# Example of how a formula might be written by a user (for testing this file):
if __FILE__ == $0
  # This part is for direct testing of the DSL, not for actual use by generator
  module HomebrewStyleDSL
    class MyTestFormula < Formula
      desc "My test formula"
      homepage "http://example.com"
      version "1.0"

      def install
        # This is how a user would define install steps
        define_install_steps do
          system "mkdir", "-p", bin
          system "echo", "hello", ">", File.join(bin, "mytest")
          system "chmod", "+x", File.join(bin, "mytest")
        end
      end
    end
  end

  formula_instance = HomebrewStyleDSL::MyTestFormula.new
  formula_instance.install # Call install to populate commands

  puts "Formula Name: #{formula_instance.name}"
  puts "Description: #{formula_instance.desc}"
  puts "Version: #{formula_instance.version}"
  puts "Install commands:"
  formula_instance.install_commands.each { |cmd| puts "  #{cmd}" }
  puts "Bin path: #{formula_instance.bin}"
end
