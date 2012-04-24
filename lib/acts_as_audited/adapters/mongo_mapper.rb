require 'mongo_mapper'
require 'acts_as_audited/auditor'
require 'acts_as_audited/adapters/mongo_mapper/audit'

module Audited::Auditor::ClassMethods
  def default_ignored_attributes
    ['id']
  end
end

::MongoMapper::Document.plugin Audited::Auditor

Audited.audit_class = Audited::Adapters::MongoMapper::Audit

require 'acts_as_audited/sweeper'
