# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = 'acts_as_audited'
  gem.version = '2.1.0'

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/acts_as_audited'

  gem.add_development_dependency 'mongo_mapper'
  gem.add_development_dependency 'rails', '~> 3.0'

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(/^spec\//)
  gem.require_paths = ['lib']
end

