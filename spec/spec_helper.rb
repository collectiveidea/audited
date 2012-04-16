ENV['RAILS_ENV'] = 'test'

require 'rails/all'
require 'acts_as_audited'
require 'audited_spec_helpers'

SPEC_ROOT = Pathname.new(File.expand_path('../', __FILE__))

Dir[SPEC_ROOT.join('support/*.rb')].each{|f| require f }

RSpec.configure do |config|
  config.include AuditedSpecHelpers

  config.before(:each, :adapter => :active_record) do
    ActsAsAudited.audit_class = ActsAsAudited::Adapters::ActiveRecord::Audit
  end

  config.before(:each, :adapter => :mongo_mapper) do
    ActsAsAudited.audit_class = ActsAsAudited::Adapters::MongoMapper::Audit
  end
end
