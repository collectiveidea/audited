module CollectiveIdea #:nodoc:
  module ActionController #:nodoc:
    module Audited #:nodoc:
      def audit(*models)
        ActiveSupport::Deprecation.warn("#audit is deprecated. Declare #acts_as_audited in your models.", caller)

        options = models.extract_options!

        # Parse the options hash looking for classes
        options.each_key do |key|
          models << [key, options.delete(key)] if key.is_a?(Class)
        end

        models.each do |(model, model_options)|
          model.send :acts_as_audited, model_options || {}
        end
      end
    end
  end
end

class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:

  cattr_accessor :current_user_method
  self.current_user_method = :current_user

  def before_create(audit)
    audit.user ||= current_user
  end

  def current_user
    if controller && controller.respond_to?(self.class.current_user_method, true)
      return User.find(params[:user_id]) if params[:user_id]
      return controller.send self.class.current_user_method
    end
  end
end

ActionController::Base.class_eval do
  extend CollectiveIdea::ActionController::Audited
  cache_sweeper :audit_sweeper
end
Audit.add_observer(AuditSweeper.instance)
