
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
        # You can optionally pass options for each model to be audited:
        #
        #    audit User, Widget, Task => { :except => :position }
        #
        # NOTE: Models which do not have options must be listed first in the
        # call to <tt>audit</tt>.
        #
        # See <tt>CollectiveIdea::Acts::Audited::ClassMethods#acts_as_audited</tt>
        # for configuration options
        #
        # You can also specify an options hash which will be passed on to
        # Rails' cache_sweeper call:
        #
        #    audit User, :only => [:create, :edit, :destroy],
        #
        def audit(*models)
          options = models.extract_options!

          # Parse the options hash looking for classes
          options.each_key do |key|
            models << [key, options.delete(key)] if key.is_a?(Class)
          end

          models.each do |(model, model_options)|
            model.send :acts_as_audited, model_options || {}
          end

          class_eval do
            # prevent observer from being registered multiple times
            Audit.delete_observer(AuditSweeper.instance)
            Audit.add_observer(AuditSweeper.instance)      
            cache_sweeper :audit_sweeper, options
          end
        end
      end

    end
  end
end

class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:
  def before_create(record)
    record.user ||= current_user
  end

  def current_user
    controller.send :current_user if controller.respond_to?(:current_user, true)
  end
end
