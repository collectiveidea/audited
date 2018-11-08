require 'active_record'

module Audited
  class << self
    attr_accessor :ignored_attributes, :current_user_method, :max_audits
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

    def auditing_enabled
      Thread.current.key?(:auditing_enabled) ? Thread.current[:auditing_enabled] : true
    end

    def auditing_enabled=(val)
      Thread.current[:auditing_enabled] = !!val
    end

    # Executes the block with auditing disabled.
    #
    #   Audited.without_auditing do
    #     ...
    #   end
    #
    def without_auditing
      auditing_was_enabled = self.auditing_enabled
      self.auditing_enabled = false
      yield
    ensure
      self.auditing_enabled = true if auditing_was_enabled
    end
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user
end

require 'audited/auditor'
require 'audited/audit'

::ActiveRecord::Base.send :include, Audited::Auditor
::Audited.auditing_enabled = true

require 'audited/sweeper'
