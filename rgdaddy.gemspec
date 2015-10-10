# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rgdaddy/version'

Gem::Specification.new do |spec|
  spec.name          = "rgdaddy"
  spec.version       = RGDaddy::VERSION
  spec.authors       = ["Xavier Panadero Lleonart"]
  spec.email         = ["xpanadero@gmail.com"]

  spec.summary       = %{Ruby GoDaddy DNS Client}
  spec.description   = %q{A gem that allows you to modify GoDaddy DNS A Records. GoDaddy active account and DNS zone is required}
  spec.homepage      = "https://github.com/xpanadero"
  spec.license       = "MIT"
  spec.required_ruby_version = '~> 2.0'


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri', '>= 1.6.6.2'

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest', '~> 5.0.0'
end
