# frozen_string_literal: true

module Audited
  class Sweeper
    STORED_DATA = {
      current_remote_address: :remote_ip,
      current_request_uuid: :request_uuid,
      current_user: :current_user
    }

    @warned_for_methods = {}
    @warned_for_methods_mutex = Mutex.new

    class << self
      attr_reader :warned_for_methods, :warned_for_methods_mutex
    end

    delegate :store, to: ::Audited

    def around(controller)
      self.controller = controller
      STORED_DATA.each { |k, m| store[k] = send(m) }
      yield
    ensure
      self.controller = nil
      STORED_DATA.keys.each { |k| store.delete(k) }
    end

    def current_user
      lambda {
        method = Audited.current_user_method
        if controller.respond_to?(method, true)
          controller.send(method)
        else
          warn_missing_current_user_method(method)
          nil
        end
      }
    end

    def remote_ip
      controller.try(:request).try(:remote_ip)
    end

    def request_uuid
      controller.try(:request).try(:uuid)
    end

    def controller
      store[:current_controller]
    end

    def controller=(value)
      store[:current_controller] = value
    end

    private

    def warn_missing_current_user_method(method)
      self.class.warned_for_methods_mutex.synchronize do
        return if self.class.warned_for_methods[method]
        self.class.warned_for_methods[method] = true
      end

      message = "[audited] #{controller.class}##{method} is not defined. " \
                "Audit records will have a nil user."
      if defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
        ::Rails.logger.warn(message)
      else
        warn(message)
      end
    end
  end
end
