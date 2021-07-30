require 'active_record'

module Audited
  class << self
    attr_accessor :ignored_attributes, :current_user_method, :max_audits, :auditing_enabled,
                  :namespace_conditions
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

    def dev_test_schema
      proc do
        create_table :audits do |t|
          t.column :auditable_id, :string
          t.column :auditable_type, :string
          t.column :associated_id, :string
          t.column :associated_type, :string
          t.column :user_id, :string
          t.column :user_type, :string
          t.column :username, :string
          t.column :action, :string
          t.column :audited_changes, :text
          t.column :json_audited_changes, :text
          t.column :version, :integer, default: 0
          t.column :comment, :string
          t.column :remote_address, :string
          t.column :request_uuid, :string
          t.column :created_at, :datetime
          t.column :service_name, :string
        end
      end
    end
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)
  @namespace_conditions = {}

  @current_user_method = :current_user
  @auditing_enabled = true
end

require 'audited/auditor'
require 'audited/audit'

::ActiveRecord::Base.send :include, Audited::Auditor

require 'audited/sweeper'
