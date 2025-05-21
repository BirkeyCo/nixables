# Ruby-to-Nix Flake Generator

This project provides a framework for generating Nix Flakes from package recipes written in a Ruby DSL. This allows users to define how a package should be built using Ruby, which is then translated into a `flake.nix` file that Nix can use.

## Project Structure

-   `recipes/`: Contains the package definitions written in Ruby.
    -   Example: `recipes/hello.rb`
-   `lib/`: Contains the Ruby DSL (`recipe_dsl.rb`) used in the recipes.
-   `generator/`: Contains the script (`generate_flake.rb`) to convert Ruby recipes into Nix Flakes.
-   `flakes/`: This directory is created by the generator. It stores the generated Nix Flakes and their associated source files.
    -   Example: `flakes/hello/flake.nix`
    -   Example: `flakes/hello/src_files/*`

## Getting Started: "Hello World" Example

This section guides you through generating a Nix Flake for a simple "hello world" package.

### 1. The Recipe (`recipes/hello.rb`)

Recipes are defined in Ruby. Here's the "hello world" example:

```ruby
# recipes/hello.rb
package "hello" do
  set_version "0.1.0" # Use set_version to define the package version

  output do
    # This block defines what the package will output/install.
    # The following command creates a script file named 'hello' in a 'bin' subdirectory.
    write_file "bin/hello", <<~SCRIPT
      #!/bin/sh
      echo "Hello, World from Nix Flake!"
    SCRIPT
    # This command marks the 'bin/hello' script as executable.
    make_executable "bin/hello"
  end
end
```

**DSL Methods:**

*   `package "name" do ... end`: Defines a new package.
*   `set_version "version_string"`: Sets the package version.
*   `output do ... end`: A block to define the build outputs.
*   `write_file "relative/path/to/file", "content"`: Writes content to a file that will be part of the package's source.
*   `make_executable "relative/path/to/file"`: Specifies that the given file should be made executable in the final package.

### 2. Generating the Nix Flake

To generate the Nix Flake from a recipe:

1.  Ensure you have Ruby installed.
2.  Navigate to the root of this project directory.
3.  Run the generator script, providing the path to the recipe:

    ```bash
    ruby generator/generate_flake.rb recipes/hello.rb
    ```

4.  This will produce the following output:
    -   `flakes/hello/src_files/bin/hello`: The actual shell script.
    -   `flakes/hello/flake.nix`: The generated Nix Flake.

### 3. Using the Flake (Conceptual)

Once the `flake.nix` is generated, you would typically use Nix commands to build and run the package. For example:

```bash
# Navigate to the flake's directory
cd flakes/hello

# Build the package
nix build

# Run the executable (path may vary based on Nix version)
./result/bin/hello
```

(Note: Actual Nix commands and usage are beyond the scope of this generator's README for now but are provided for context.)

## Future Development

This is an initial framework. Future enhancements could include:
-   Dependency management.
-   More complex build steps.
-   Support for different types of sources (e.g., tarballs, Git repositories).
-   Automated testing of generated Flakes.
```
