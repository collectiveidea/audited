# frozen_string_literal: true

# Abstract class connecting to OMS_DB
# As of Rails 6.1 has to be abstract
# to allow use of .connects_to
# And inherithing from Audited::Audit
#
class OmsAuditlike < Audited::Audit
  self.abstract_class = true

  # OMS_DB = :oms

  # connects_to database: {
  #   writing: OMS_DB,
  #   reading: OMS_DB
  # }
end
