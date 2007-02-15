
module CollectiveIdea #:nodoc:
  module ActionController #:nodoc:
    module Audited #:nodoc:

      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end

      module ClassMethods
        # Declare models that should be audited in your controller
        #
        #   class ApplicationController < ActionController::Base
        #     audit User, Widget
        #   end
        #
        def audit(*models)
          AuditSweeper.class_eval do
            observe *models
            models.each do |clazz|
              clazz.send :acts_as_audited unless clazz.respond_to?(:disable_auditing)
              # disable automatic auditing
              clazz.send :disable_auditing
            end
            
          end
          class_eval do
            cache_sweeper :audit_sweeper
          end
        end
      end
      
    end
  end
end

class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:

  def after_create(record)
    record.send(:write_audit, :create, current_user)
  end

  def after_destroy(record)
    record.send(:write_audit, :destroy, current_user)
  end

  def after_update(record)
    record.send(:write_audit, :update, current_user)
  end
  
  def current_user
    controller.send :current_user if controller.respond_to?(:current_user)
  end

end
