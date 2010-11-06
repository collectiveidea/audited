ENV['RAILS_ENV'] = 'test'

require 'rails'
require 'active_record'
require 'action_controller'
require 'rspec'

require 'acts_as_audited'

require 'audited_spec_helpers'

RSpec.configure do |c|
  c.include AuditedSpecHelpers
end

config = YAML::load(IO.read(File.dirname(__FILE__) + '/db/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3mem'])
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/db/schema.rb")

require 'spec_models'
