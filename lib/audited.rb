require 'active_record'

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
      Thread.current[:audited_store] ||= {}
    end

    def config
      yield(self)
    end
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user
  @auditing_enabled = true
  @store_synthesized_enums = false
end

require 'audited/auditor'
require 'audited/audit'

::ActiveRecord::Base.send :include, Audited::Auditor

require 'audited/sweeper'
