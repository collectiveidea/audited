# frozen_string_literal: true

module Audited
  class Sweeper
    STORED_DATA = {
      current_remote_address: :remote_ip,
      current_request_uuid: :request_uuid,
      current_user: :current_user
    }

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
      lambda do
        method_name = Audited.current_user_method
        unless controller.respond_to?(method_name, true)
          raise NoMethodError,
            "The configured Audited.current_user_method (#{method_name.inspect}) " \
            "is not defined on #{controller.class}. " \
            "Please configure Audited.current_user_method to a method that exists on your controller."
        end
        controller.send(method_name)
      end
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
  end
end
