# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)
require "audited/version"
require "audited/mongo_mapper/version"

Gem::Specification.new do |gem|
  gem.name    = 'audited-mongo_mapper'
  gem.version = Audited::MongoMapper::VERSION

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your MongoMapper models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/audited'
  gem.license     = 'MIT'

  gem.add_dependency 'audited', Audited::VERSION
  gem.add_dependency 'mongo_mapper', '~> 0.13.0'

  gem.files         = `git ls-files lib`.split($\).grep(/mongo_mapper/)
  gem.files         << 'LICENSE'
  gem.require_paths = ['lib']
end

