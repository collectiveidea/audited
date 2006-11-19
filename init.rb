require 'audit'
require 'acts_as_audited'

ActiveRecord::Base.send :include, CollectiveIdea::Acts::Audited

if defined?(ActionController) and defined?(ActionController::Base)
  require 'audit_sweeper'
  ActionController::Base.send :include, CollectiveIdea::ActionController::Audited
end
