# frozen_string_literal: true

require "active_record"

module Audited
  class << self
    attr_accessor \
      :auditing_enabled,
      :current_user_method,
      :ignored_attributes,
      :max_audits,
      :store_synthesized_enums
    attr_writer :audit_class

    def audit_class
      @audit_class ||= Audit
    end

    def store
      current_store_value = Thread.current.thread_variable_get(:audited_store)

      if current_store_value.nil?
        Thread.current.thread_variable_set(:audited_store, {})
      else
        current_store_value
      end
    end

    def config
      yield(self)
    end
  end

  @ignored_attributes = %w[lock_version created_at updated_at created_on updated_on]

  @current_user_method = :current_user
  @auditing_enabled = true
  @store_synthesized_enums = false
end

require "audited/auditor"

ActiveSupport.on_load :active_record do
  require "audited/audit"
  include Audited::Auditor
end

require "audited/sweeper"
require "audited/railtie"
