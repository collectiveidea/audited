ENV['RAILS_ENV'] = 'test'

require 'protected_attributes'
require 'rails_app/config/environment'
require 'rspec/rails'
require 'audited'
require 'audited_spec_helpers'

SPEC_ROOT = Pathname.new(File.expand_path('../', __FILE__))

Dir[SPEC_ROOT.join('support/*.rb')].each{|f| require f }

RSpec.configure do |config|
  config.include AuditedSpecHelpers

  config.before(:each, :adapter => :active_record) do
    Audited.audit_class = Audited::Adapters::ActiveRecord::Audit
  end

  config.before(:each, :adapter => :postgresql) do
    Audited.audit_class = Audited::Adapters::Postgresql::Audit
  end

  config.before(:each, :adapter => :mongo_mapper) do
    Audited.audit_class = Audited::Adapters::MongoMapper::Audit
  end
end
