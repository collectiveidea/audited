require 'active_record'
require 'acts_as_audited/auditor'
require 'acts_as_audited/adapters/active_record/audit'

module Audited::Auditor::ClassMethods
  def default_ignored_attributes
    [self.primary_key, inheritance_column]
  end
end

::ActiveRecord::Base.send :include, Audited::Auditor

Audited.audit_class = Audited::Adapters::ActiveRecord::Audit

require 'acts_as_audited/sweeper'
