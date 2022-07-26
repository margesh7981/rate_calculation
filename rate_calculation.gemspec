# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rate_calculation/version'

Gem::Specification.new do |spec|
  spec.name          = "rate_calculation"
  spec.version       = RateCalculation::VERSION
  spec.authors       = ["Margesh Sonawane"]
  spec.email         = ["margesh.sonawane@gmail.com"]
  spec.summary       = %q{Gem written to calculate rate between to Ports}
  spec.description   = %q{Gem written to calculate rate between to Ports }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
