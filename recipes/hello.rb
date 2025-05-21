package "hello" do
  set_version "0.1.0" # Changed from 'version' to 'set_version'

  output do
    write_file "bin/hello", <<~SCRIPT
      #!/bin/sh
      echo "Hello, World from Nix Flake!"
    SCRIPT
    make_executable "bin/hello"
  end
end
