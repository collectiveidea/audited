# frozen_string_literal: true
require 'audited'
require 'audited/audit'
# Explicitly load up abstract klass
# require 'oms_auditlike'
# Explicitly load up OmsAudit
# require 'oms_audit'

Audited.config do |_config|
  # do no thing for now
  # config.audit_class = OmsAudit
end
