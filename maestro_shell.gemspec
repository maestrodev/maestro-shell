# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'util/version'

Gem::Specification.new do |spec|
  spec.name          = 'maestro_shell'
  spec.version       = Maestro::Util::Shell::VERSION
  spec.authors       = ['Doug Henderson']
  spec.email         = ['dhenderson@maestrodev.com']
  spec.description   = %q{A ruby library to help with the creation of Maestro plugins that need Shell functionality}
  spec.summary       = %q{Maestro Shell utility}
  spec.homepage      = 'https://github.com/maestrodev/maestro-shell'
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'childprocess', '>= 0.3.9'

  spec.add_development_dependency "mocha", '>=0.10.0'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.13'
  spec.add_development_dependency 'maestro_plugin', '>=0.0.17' # for logging <<- who made this dep on maestro_plugin... you will be destroyed!
end
