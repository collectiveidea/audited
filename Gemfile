source 'https://rubygems.org'

gemspec :name => 'audited'
# JRuby support for the test ENV
unless defined?(JRUBY_VERSION)
  gem 'sqlite3', '~> 1.2'
  gem 'mysql2', '~> 0.3'
  gem 'pg', '~> 0.17'
  gem 'bson_ext', '~> 1.6'
else
  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3'
  gem 'activerecord-jdbcpostgresql-adapter', '~> 1.3'
  gem 'activerecord-jdbcmysql-adapter', '~> 1.3'
  gem 'bson', '~> 1.6'
end