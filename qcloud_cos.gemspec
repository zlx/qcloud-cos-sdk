# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qcloud_cos/version'

Gem::Specification.new do |spec|
  spec.name          = 'qcloud_cos'
  spec.version       = QcloudCos::VERSION
  spec.authors       = ['Newell Zhu']
  spec.email         = ['zlx.star@gmail.com']

  spec.summary       = 'Ruby SDK For QCloud COS, Enjoy it!'
  spec.description   = 'Ruby SDK For QCloud COS, Enjoy it!'
  spec.homepage      = 'https://github.com/tencentyun'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['qcloud-cos']
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty'
  spec.add_dependency 'httmultiparty'
  spec.add_dependency 'addressable'
  spec.add_dependency 'commander'
  spec.add_dependency 'awesome_print'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'rubocop'
end
