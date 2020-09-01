# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'working_set'

Gem::Specification.new do |spec|

  spec.name          = "working_set"
  spec.version       = WorkingSet::VERSION
  spec.authors       = ["Jim Garvin"]
  spec.email         = ["jim@thegarvin.com"]
  spec.summary       = %q{Code search companion for your terminal-based text editor.}
  spec.description   = %q{It's an ncurses-based thing.}
  spec.homepage      = "https://github.com/coderifous/working_set"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_dependency "zeitwerk", "~> 2.4"
  spec.add_dependency "celluloid", "~> 0.17"
  spec.add_dependency "celluloid-io", "~> 0.17"
  spec.add_dependency "celluloid-supervision", "~> 0.20.6"
  spec.add_dependency "ncurses-ruby", "~> 1.2"
  spec.add_dependency "listen", "~> 3.2"
  spec.add_dependency "clipboard", "~> 1.3"
  spec.add_dependency "tty-option", "~> 0.1"

end
