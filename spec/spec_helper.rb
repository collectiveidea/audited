ENV['RAILS_ENV'] = 'test'

require 'protected_attributes'
require 'rails_app/config/environment'
require 'rspec/rails'
require 'audited'
require 'audited_spec_helpers'
require 'support/active_record/models'
load "audited/sweeper.rb" # force to reload sweeper

SPEC_ROOT = Pathname.new(File.expand_path('../', __FILE__))

Dir[SPEC_ROOT.join('support/*.rb')].each{|f| require f }

RSpec.configure do |config|
  config.include AuditedSpecHelpers
end
