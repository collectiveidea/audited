require 'mongo_mapper'
require 'acts_as_audited/auditor'
require 'acts_as_audited/adapters/mongo_mapper/audit'

module ActsAsAudited::Auditor::ClassMethods
  def default_ignored_attributes
    ['id']
  end
end

::MongoMapper::Document.plugin ActsAsAudited::Auditor

ActsAsAudited.audit_class = ActsAsAudited::Adapters::MongoMapper::Audit

require 'acts_as_audited/sweeper'
