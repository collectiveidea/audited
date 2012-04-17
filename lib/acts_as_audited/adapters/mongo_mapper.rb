require 'mongo_mapper'
require 'acts_as_audited/adapters/mongo_mapper/auditor'
require 'acts_as_audited/adapters/mongo_mapper/audit'

::MongoMapper::Document.plugin ActsAsAudited::Adapters::MongoMapper::Auditor

ActsAsAudited.audit_class = ActsAsAudited::Adapters::MongoMapper::Audit

require 'acts_as_audited/sweeper'
