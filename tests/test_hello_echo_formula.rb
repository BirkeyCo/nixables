# tests/test_hello_echo_formula.rb
require 'fileutils'
require 'minitest/autorun'
require 'open3'

class TestHelloEchoFormulaGeneration < Minitest::Test
  BASE_DIR = File.expand_path('..', __dir__) # Project root
  GENERATOR_SCRIPT = File.join(BASE_DIR, 'generator', 'generate_flake.rb')
  # Ensure the DSL is loaded for the test environment if generator doesn't handle it for direct class refs
  # require_relative File.join(BASE_DIR, 'lib', 'formula_dsl.rb')

  RECIPE_FILE = File.join(BASE_DIR, 'recipes', 'hello_echo_formula.rb')
  PACKAGE_NAME = "HelloEchoFormula" # Expected package name from the class name

  FLAKE_OUTPUT_DIR = File.join(BASE_DIR, 'flakes', PACKAGE_NAME)
  GENERATED_FLAKE_FILE = File.join(FLAKE_OUTPUT_DIR, 'flake.nix')
  GENERATED_EMPTY_SRC_DIR = File.join(FLAKE_OUTPUT_DIR, 'empty_src')

  FIXTURE_DIR = File.join(BASE_DIR, 'tests', 'fixtures')
  EXPECTED_FLAKE_FIXTURE_FILE = File.join(FIXTURE_DIR, 'expected_hello_echo_formula_flake.nix')

  def setup
    FileUtils.chmod('+x', GENERATOR_SCRIPT) unless File.executable?(GENERATOR_SCRIPT)
    FileUtils.rm_rf(File.join(BASE_DIR, 'flakes', PACKAGE_NAME)) # Clean specific package output
    FileUtils.mkdir_p(FIXTURE_DIR) unless Dir.exist?(FIXTURE_DIR)
    puts "Setup complete for TestHelloEchoFormulaGeneration. Cleaned flakes/\#{PACKAGE_NAME} directory."
  end

  def run_generator
    puts "Running generator: ruby \#{GENERATOR_SCRIPT} \#{RECIPE_FILE}"
    # Ensure the DSL is available to the generator script when it `load`s the recipe
    # This might involve setting RUBYLIB or ensuring require_relative paths are correct in the generator
    cmd = ["ruby", GENERATOR_SCRIPT, RECIPE_FILE]
    # Use Open3.capture3 with individual arguments for better safety with paths
    stdout, stderr, status = Open3.capture3(*cmd)

    puts "Generator STDOUT: \#{stdout}"
    puts "Generator STDERR: \#{stderr}"
    unless status.success?
      puts "Generator script failed!"
    end
    status.success?
  end

  def test_hello_echo_formula_flake_generation
    puts "Starting test_hello_echo_formula_flake_generation..."

    assert run_generator, "Generator script failed to execute successfully."

    # 1. Check if generated empty_src directory exists
    assert Dir.exist?(GENERATED_EMPTY_SRC_DIR), "Generated empty_src directory '\#{GENERATED_EMPTY_SRC_DIR}' not found."
    puts "Verified existence of empty_src directory."

    # 2. Check if generated flake.nix exists
    assert File.exist?(GENERATED_FLAKE_FILE), "Generated flake.nix '\#{GENERATED_FLAKE_FILE}' not found."
    puts "Verified existence of flake.nix."

    # 3. Check flake.nix content against fixture
    assert File.exist?(EXPECTED_FLAKE_FIXTURE_FILE), "Fixture file '\#{EXPECTED_FLAKE_FIXTURE_FILE}' not found. This is a test setup error."

    expected_flake_content = File.read(EXPECTED_FLAKE_FIXTURE_FILE)
    actual_flake_content = File.read(GENERATED_FLAKE_FILE)

    normalized_expected = expected_flake_content.gsub("\r\n", "\n").strip
    normalized_actual = actual_flake_content.gsub("\r\n", "\n").strip

    assert_equal normalized_expected, normalized_actual, "Content of generated flake.nix does not match the expected fixture."
    puts "Verified flake.nix content against fixture."

    puts "test_hello_echo_formula_flake_generation PASSED."
  end

  def teardown
    puts "Teardown for TestHelloEchoFormulaGeneration: No specific actions needed."
  end
end

puts "TestHelloEchoFormulaGeneration class defined. Running tests..."
