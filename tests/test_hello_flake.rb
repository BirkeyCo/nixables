# tests/test_hello_flake.rb
require 'fileutils'
require 'minitest/autorun'
require 'open3'

class TestHelloFlakeGeneration < Minitest::Test
  BASE_DIR = File.expand_path('..', __dir__) # Project root
  GENERATOR_SCRIPT = File.join(BASE_DIR, 'generator', 'generate_flake.rb')
  RECIPE_FILE = File.join(BASE_DIR, 'recipes', 'hello.rb')
  
  FLAKE_OUTPUT_DIR = File.join(BASE_DIR, 'flakes', 'hello') # Renamed for clarity
  GENERATED_FLAKE_FILE = File.join(FLAKE_OUTPUT_DIR, 'flake.nix')
  GENERATED_SOURCE_SCRIPT = File.join(FLAKE_OUTPUT_DIR, 'src_files', 'bin', 'hello')

  FIXTURE_DIR = File.join(BASE_DIR, 'tests', 'fixtures')
  EXPECTED_FLAKE_FIXTURE_FILE = File.join(FIXTURE_DIR, 'expected_hello_flake.nix')

  EXPECTED_SCRIPT_CONTENT = <<~SCRIPT.strip
    #!/bin/sh
    echo "Hello, World from Nix Flake!"
  SCRIPT

  def setup
    FileUtils.chmod('+x', GENERATOR_SCRIPT) unless File.executable?(GENERATOR_SCRIPT)
    FileUtils.rm_rf(File.join(BASE_DIR, 'flakes')) # Clean all flakes output
    # Ensure fixture directory exists for safety, though it should be created by the subtask
    FileUtils.mkdir_p(FIXTURE_DIR) unless Dir.exist?(FIXTURE_DIR)
    puts "Setup complete. Cleaned flakes directory."
  end

  def run_generator
    puts "Running generator: ruby #{GENERATOR_SCRIPT} #{RECIPE_FILE}"
    stdout, stderr, status = Open3.capture3("ruby", GENERATOR_SCRIPT, RECIPE_FILE)
    puts "Generator STDOUT: #{stdout}"
    puts "Generator STDERR: #{stderr}"
    unless status.success?
      puts "Generator script failed!"
      puts "STDOUT: #{stdout}"
      puts "STDERR: #{stderr}"
    end
    status.success?
  end

  def test_flake_generation_and_exact_content
    puts "Starting test_flake_generation_and_exact_content..."

    assert run_generator, "Generator script failed to execute successfully."

    # 1. Check source script existence and content (no change here)
    assert File.exist?(GENERATED_SOURCE_SCRIPT), "Generated source script '#{GENERATED_SOURCE_SCRIPT}' not found."
    actual_script_content = File.read(GENERATED_SOURCE_SCRIPT).strip
    assert_equal EXPECTED_SCRIPT_CONTENT, actual_script_content, "Content of generated script does not match expected."
    puts "Verified source script content."

    # 2. Check flake.nix existence
    assert File.exist?(GENERATED_FLAKE_FILE), "Generated flake.nix '#{GENERATED_FLAKE_FILE}' not found."
    puts "Verified existence of flake.nix."

    # 3. Check flake.nix content against fixture
    assert File.exist?(EXPECTED_FLAKE_FIXTURE_FILE), "Fixture file '#{EXPECTED_FLAKE_FIXTURE_FILE}' not found. This is a test setup error."
    
    expected_flake_content = File.read(EXPECTED_FLAKE_FIXTURE_FILE)
    actual_flake_content = File.read(GENERATED_FLAKE_FILE)
    
    # Normalize line endings to LF for comparison, and remove trailing newlines
    normalized_expected = expected_flake_content.gsub("\r\n", "\n").strip
    normalized_actual = actual_flake_content.gsub("\r\n", "\n").strip

    assert_equal normalized_expected, normalized_actual, "Content of generated flake.nix does not match the expected fixture."
    puts "Verified flake.nix content against fixture."

    puts "test_flake_generation_and_exact_content PASSED."
  end

  def teardown
    puts "Teardown: No specific actions needed."
  end
end

puts "TestHelloFlakeGeneration class defined. Running tests..."
