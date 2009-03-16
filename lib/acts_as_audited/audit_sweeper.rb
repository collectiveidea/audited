
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
        # You can optionally pass an options hash for each model to be
        # audited:
        #
        #    audit User, Task, :user => { :except => :password }, :task => { :except => :position }
        #
        # See <tt>CollectiveIdea::Acts::Audited::ClassMethods#acts_as_audited</tt>
        # for configuration options
        #
        # You can also specify an options hash which will be passed on to
        # Rails' cache_sweeper call:
        #
        #    audit User, :only => [:create, :edit, :destroy]
        #
        def audit(*models)
          options = models.extract_options!
          models.each do |clazz|

            # Handle model specific options
            model_options = options.delete(clazz.to_s.downcase.to_sym)
            model_options ||= {}

            clazz.send :acts_as_audited, model_options
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
