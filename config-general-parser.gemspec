# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'config_general_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "config_general_parser"
  spec.version       = ConfigGeneralParser::VERSION
  spec.authors       = ["Thom May"]
  spec.email         = ["tmay@expedia.com"]
  spec.description   = %q{Parser to deal with perl's unholy Config::General thing}
  spec.summary       = %q{Parser to deal with perl's unholy Config::General thing}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
  spec.add_dependency "parslet"
end
