ENV['RAILS_ENV'] = 'test'

$:.unshift File.dirname(__FILE__)

require 'rails_app/config/environment'
require 'rspec/rails'

require 'acts_as_audited'

require 'audited_spec_helpers'

RSpec.configure do |c|
  c.include AuditedSpecHelpers

  c.before(:suite) do
    ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
    ActiveRecord::Migration.verbose = false
    load(File.dirname(__FILE__) + "/db/schema.rb")
    require 'spec_models'
  end
end
