require 'mongo_mapper'
require 'audited/auditor'
require 'audited/adapters/mongo_mapper/audited_changes'
require 'audited/adapters/mongo_mapper/audit'

module Audited::Auditor::ClassMethods
  def default_ignored_attributes
    ['id', '_id']
  end
end

::MongoMapper::Document.plugin Audited::Auditor

Audited.audit_class = Audited::Adapters::MongoMapper::Audit

require 'audited/sweeper'
