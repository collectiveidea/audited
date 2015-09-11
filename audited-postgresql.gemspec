# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)
require "audited/version"
require "audited/postgresql/version"

Gem::Specification.new do |gem|
  gem.name    = 'audited-postgresql'
  gem.version = Audited::Postgresql::VERSION

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your ActiveRecord models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/audited'
  gem.license     = 'MIT'

  gem.add_dependency 'audited', Audited::VERSION
  gem.add_dependency 'activerecord', '~> 4.0'

  gem.files         = `git ls-files lib`.split($\).grep(/(postgresql|generators)/)
  gem.files         << 'LICENSE'
  gem.require_paths = ['lib']
end
