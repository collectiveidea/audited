
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
        #    audit User, :only => [:create, :edit, :destroy]
        #
        def audit(*models_with_options)

          options = models_with_options.extract_options!
          models  = models_with_options # remaining models (without options)

          # Parse the options hash looking for classes
          options.each_key do |key|
            if key.is_a?(Class)
              models << [key, options.delete(key)]
            end
          end

          models.each do |model|

	    # Handle models which may have options
            if model.is_a?(Array)
              clazz         = model.first
              clazz_options = model.last
            elsif model.is_a?(Class)
              clazz         = model
              clazz_options = {}
            else
              next
            end

            clazz.send :acts_as_audited, clazz_options

            # disable ActiveRecord callbacks, which are replaced by the AuditSweeper
            clazz.send :disable_auditing_callbacks
            clazz.add_observer(AuditSweeper.instance)
          end

          class_eval do
            cache_sweeper :audit_sweeper, options
          end
        end
      end

    end
  end
end

class AuditSweeper < ActionController::Caching::Sweeper #:nodoc:

  def after_create(record)
    record.send(:audit_create, current_user)
  end

  def after_destroy(record)
    record.send(:audit_destroy, current_user)
  end

  def before_update(record)
    record.send(:audit_update, current_user)
  end

  def current_user
    controller.send :current_user if controller.respond_to?(:current_user)
  end

end
