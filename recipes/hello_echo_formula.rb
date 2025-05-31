# recipes/hello_echo_formula.rb

# This line might be needed if the generator doesn't automatically load the DSL
# require_relative '../lib/formula_dsl' # Adjust path if necessary

class HelloEchoFormula < HomebrewStyleDSL::Formula
  desc "A simple formula that installs an echo script"
  homepage "https://example.com/hello-echo"
  version "0.1.0"

  def install
    define_install_steps do
      system "mkdir", "-p", bin
      # Corrected quoting for inner double quotes and interpolation for bin
      system "sh", "-c", "echo '#!/bin/sh\necho \"Hello, Echo from Homebrew-style formula!\"' > #{bin}/hello-echo"
      system "chmod", "+x", "#{bin}/hello-echo" # Corrected interpolation for chmod target
    end
  end
end
