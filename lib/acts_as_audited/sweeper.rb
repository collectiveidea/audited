module Audited
  class Sweeper < ActiveModel::Observer
    observe Audited.audit_class

    attr_accessor :controller

    def before(controller)
      self.controller = controller
      true
    end

    def after(controller)
      self.controller = nil
    end

    def before_create(audit)
      audit.user ||= current_user
      audit.remote_address = controller.try(:request).try(:ip)
    end

    def current_user
      controller.send(Audited.current_user_method) if controller.respond_to?(Audited.current_user_method, true)
    end

    def add_observer!(klass)
      super
      define_callback(klass)
    end

    def define_callback(klass)
      observer = self
      callback_meth = :"_notify_audited_sweeper"
      klass.send(:define_method, callback_meth) do
        observer.update(:before_create, self)
      end
      klass.send(:before_create, callback_meth)
    end
  end
end

if defined?(ActionController) and defined?(ActionController::Base)
  ActionController::Base.class_eval do
    around_filter Audited::Sweeper.instance
  end
end
