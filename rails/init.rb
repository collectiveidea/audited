require 'audit_module'
require 'acts_as_audited/audit'
require 'acts_as_audited'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Audited

if defined?(ActionController) and defined?(ActionController::Base)
  require 'acts_as_audited/audit_sweeper'
end
