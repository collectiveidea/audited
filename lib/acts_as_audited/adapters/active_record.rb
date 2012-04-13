require 'active_record'
require 'acts_as_audited/adapters/active_record/auditor'
require 'acts_as_audited/adapters/active_record/audit'

::ActiveRecord::Base.send :include, ActsAsAudited::Adapters::ActiveRecord::Auditor

ActsAsAudited.audit_class = ActsAsAudited::Adapters::ActiveRecord::Audit
