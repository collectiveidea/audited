# frozen_string_literal: true

module Audited
  class AuditAssociation < ActiveRecord::Base
    belongs_to :audit
    belongs_to :associated, polymorphic: true
  end
end
