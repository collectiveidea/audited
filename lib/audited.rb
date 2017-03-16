require 'active_record'

module Audited
  class << self
    attr_accessor :ignored_attributes, :current_user_method

    # Deprecate audit_class accessors in preperation of their removal
    def audit_class
      Audited::Audit
    end
    deprecate audit_class: "Audited.audit_class is now always Audited::Audit. This method will be removed."

    def store
      Thread.current[:audited_store] ||= {}
    end
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user
end

require 'audited/auditor'
require 'audited/audit'

::ActiveRecord::Base.send :include, Audited::Auditor

require 'audited/sweeper'
