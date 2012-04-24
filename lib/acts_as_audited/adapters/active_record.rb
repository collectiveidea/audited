require 'active_record'
require 'acts_as_audited/auditor'
require 'acts_as_audited/adapters/active_record/audit'

module ActsAsAudited::Auditor::ClassMethods
  def default_ignored_attributes
    [self.primary_key, inheritance_column]
  end
end

::ActiveRecord::Base.send :include, ActsAsAudited::Auditor

ActsAsAudited.audit_class = ActsAsAudited::Adapters::ActiveRecord::Audit

require 'acts_as_audited/sweeper'
