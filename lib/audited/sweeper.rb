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
        if controller.respond_to?(Audited.current_user_method, true)
          controller.send(Audited.current_user_method)
        else
          if controller.respond_to?(:current_spree_user)
            controller.send(:current_spree_user)
          end
        end
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
