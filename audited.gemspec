# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name    = 'audited'
  gem.version = '3.0.0'

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/audited'
  gem.license     = 'MIT'

  gem.add_development_dependency 'appraisal', '~> 1.0'
  gem.add_development_dependency 'bson_ext'
  gem.add_development_dependency 'mongo_mapper'
  gem.add_development_dependency 'rails'
  gem.add_development_dependency 'rspec-rails', '~> 2.0'
  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'pry'

  gem.files         = `git ls-files`.split($\).reject{|f| f =~ /(\.gemspec|lib\/audited\-|adapters|generators)/ }
  gem.test_files    = gem.files.grep(/^spec\//)
  gem.require_paths = ['lib']
end

