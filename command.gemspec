# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'command/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.0'
  s.name          = 'command'
  s.version       = Command::VERSION
  s.authors       = ['Andrea Pavoni', 'Guillaume Charneau', 'Jérémie Bonal']
  s.email         = ['andrea.pavoni@gmail.com', 'guillaume.charneau@swile.co', 'jeremie.bonal@swile.co']
  s.summary       = 'Easy way to build and manage commands (service objects)'
  s.description   = 'Easy way to build and manage commands (service objects)'
  s.homepage      = 'http://github.com/TheMenu/command'
  s.license       = 'MIT'

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.test_files    = s.files.grep(/^(test|spec|features)\//)
  s.require_paths = ['lib']

  s.add_dependency 'i18n'
  s.add_dependency 'rspec'

  s.add_development_dependency 'bundler', '~> 2'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'byebug'
end
