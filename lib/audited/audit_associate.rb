module Audited
  class AuditAssociate < ::ActiveRecord::Base
    self.table_name_prefix = "audited_"

    belongs_to :audit
    belongs_to :associated, polymorphic: true
  end
end
