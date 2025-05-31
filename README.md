# Ruby-to-Nix Flake Generator

This project provides a framework for generating Nix Flakes from package recipes written in a Ruby DSL. This allows users to define how a package should be built using Ruby, which is then translated into a `flake.nix` file that Nix can use.

## Development Environment Setup

This project provides a Nix Flake (`flake.nix` at the root) to create a consistent development environment. This environment includes Ruby, which is necessary for running the generator and test scripts.

To activate the development environment:

1.  Ensure you have [Nix installed with Flakes enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes).
2.  Navigate to the root of this project directory.
3.  Run the following command to enter the development shell:

    ```bash
    nix develop
    ```
    Alternatively, you can use `nix shell .` for a more ephemeral shell.

4.  Once inside the shell, you will have Ruby available. The environment also includes Minitest (for running tests) and is configured to support multiple platforms (Linux and macOS on x86_64 and ARM architectures).

Now you can proceed to use the generator scripts or run tests as described in the sections below.

## Project Structure

-   `recipes/`: Contains the package definitions written in Ruby.
    -   Example: `recipes/hello.rb` (old style)
    -   Example: `recipes/hello_echo_formula.rb` (new Formula-style)
-   `lib/`: Contains the Ruby DSLs (`recipe_dsl.rb` for old style, `formula_dsl.rb` for new style).
-   `generator/`: Contains the script (`generate_flake.rb`) to convert Ruby recipes into Nix Flakes.
-   `flakes/`: This directory is created by the generator. It stores the generated Nix Flakes and their associated source files.
    -   Example output for `hello.rb`: `flakes/hello/flake.nix`
    -   Example output for `hello_echo_formula.rb`: `flakes/HelloEchoFormula/flake.nix`

## Formula-Style Recipes

The primary way to define packages is using "Formula-style" Ruby scripts. These scripts define a class that inherits from `HomebrewStyleDSL::Formula`.

### Formula DSL Basics

Here's a conceptual overview of the `Formula` class DSL:

-   **Class Definition**: Your recipe will define a class inheriting from `HomebrewStyleDSL::Formula`. The name of this class (e.g., `MyPackageFormula`) determines the output package name.
    ```ruby
    class MyPackageFormula < HomebrewStyleDSL::Formula
      # ... formula definition ...
    end
    ```

-   **Metadata**:
    *   `desc "description"`: A short description of the package.
    *   `homepage "url"`: The upstream homepage for the package.
    *   `version "version_string"`: The version of the package.
    *   *(Future: `url "source_url"` and `sha256 "checksum"` for source tarballs)*
    *   *(Future: `depends_on "dependency_name"` for specifying dependencies)*

-   **Installation Method**:
    *   `def install ... end`: This method defines the build and installation steps.
    *   `define_install_steps do ... end`: Inside your `install` method, you call this with a block containing the actual steps.
    *   `system "command", "arg1", "arg2", ...`: Used within the `define_install_steps` block to specify shell commands. These are recorded and translated into the Nix `installPhase`.
    *   **Path Helpers**:
        *   `prefix`: Represents the base installation directory (equivalent to `$out` in Nix).
        *   `bin`: Resolves to `"\#{prefix}/bin"`.
        *   `lib`: Resolves to `"\#{prefix}/lib"`.
        *   *(And others like `man`, `include`, etc., can be added)*

**Example: `hello_echo_formula.rb`**

The following example shows how to create a simple package that installs a script using the Formula style:

```ruby
# recipes/hello_echo_formula.rb
class HelloEchoFormula < HomebrewStyleDSL::Formula
  desc "A simple formula that installs an echo script"
  homepage "https://example.com/hello-echo"
  version "0.1.0"

  def install
    define_install_steps do
      system "mkdir", "-p", bin
      system "sh", "-c", "echo '#!/bin/sh\necho "Hello, Echo from Homebrew-style formula!"' > \#{bin}/hello-echo"
      system "chmod", "+x", "\#{bin}/hello-echo"
    end
  end
end
```

## Getting Started: "Hello World" Example (Old Style)

This section guides you through generating a Nix Flake for a simple "hello world" package using the older DSL style. For the newer Formula-style, see the section above.

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

**DSL Methods (Old Style):**

*   `package "name" do ... end`: Defines a new package.
*   `set_version "version_string"`: Sets the package version.
*   `output do ... end`: A block to define the build outputs.
*   `write_file "relative/path/to/file", "content"`: Writes content to a file that will be part of the package's source.
*   `make_executable "relative/path/to/file"`: Specifies that the given file should be made executable in the final package.

### Generating the Nix Flake

To generate the Nix Flake from a recipe:

1.  Ensure you have Ruby installed (see "Development Environment Setup").
2.  Navigate to the root of this project directory.
3.  Run the generator script, providing the path to the recipe. For a Formula-style recipe (recommended):

    ```bash
    ruby generator/generate_flake.rb recipes/hello_echo_formula.rb
    ```

    This will produce output in the `flakes/` directory, named after the Formula class:
    -   `flakes/HelloEchoFormula/empty_src/`: A placeholder directory as this formula generates its own content.
    -   `flakes/HelloEchoFormula/flake.nix`: The generated Nix Flake.

    For an older style recipe (e.g., `recipes/hello.rb`):
    ```bash
    ruby generator/generate_flake.rb recipes/hello.rb
    ```
    This will produce output like:
    -   `flakes/hello/src_files/bin/hello`: The actual shell script.
    -   `flakes/hello/flake.nix`: The generated Nix Flake.


### 3. Using the Flake (Conceptual)

Once the `flake.nix` is generated, you would typically use Nix commands to build and run the package. For example (using `HelloEchoFormula` as an example):

```bash
# Navigate to the flake's directory
cd flakes/HelloEchoFormula

# Build the package
nix build

# Run the executable (path may vary based on Nix version)
./result/bin/hello-echo
```

(Note: Actual Nix commands and usage are beyond the scope of this generator's README for now but are provided for context.)

## Future Development

This is an initial framework. Future enhancements could include:
-   Dependency management for Formula-style recipes.
-   More complex build steps and source handling (tarballs, Git repos).
-   Automated testing of generated Flakes for both DSL styles.

## Testing

This project uses Minitest for automated testing. The tests verify that the Nix Flake generator produces the expected output for the provided recipes.

### Running Tests

1.  Ensure you have Ruby and the Minitest gem installed. If you don't have Minitest, you can usually install it with:
    ```bash
    gem install minitest
    ```
2.  Navigate to the root of the project directory.
3.  Run the test script(s):

    ```bash
    ruby tests/test_hello_flake.rb
    ruby tests/test_hello_echo_formula.rb
    ```

    The script will output the test results, indicating any failures or errors.
```
