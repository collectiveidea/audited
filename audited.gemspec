# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "audited/version"

Gem::Specification.new do |gem|
  gem.name        = 'audited'
  gem.version     = Audited::VERSION
  gem.platform    = Gem::Platform::RUBY

  gem.authors     = ['Brandon Keepers', 'Kenneth Kalmer', 'Daniel Morrison', 'Brian Ryckbost', 'Steve Richert', 'Ryan Glover']
  gem.email       = 'info@collectiveidea.com'
  gem.description = 'Log all changes to your models'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/collectiveidea/audited'
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split($\).reject{|f| f =~ /(\.gemspec)/ }
  gem.require_paths = ['lib']

  gem.add_dependency 'activerecord', '>= 4.0', '< 5.1'
  gem.add_dependency 'rails-observers', '~> 0.1.2'

  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'rails', '>= 4.0', '< 5.1'
  gem.add_development_dependency 'rspec-rails', '~> 3.4'

  # JRuby support for the test ENV
  if defined?(JRUBY_VERSION)
    gem.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3'
    gem.add_development_dependency 'activerecord-jdbcpostgresql-adapter', '~> 1.3'
    gem.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.3'
  else
    gem.add_development_dependency 'sqlite3', '~> 1.3'
    gem.add_development_dependency 'mysql2', '~> 0.3.20'
    gem.add_development_dependency 'pg', '~> 0.18'
  end
end

