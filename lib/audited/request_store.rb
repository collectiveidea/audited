# frozen_string_literal: true

require "active_support/current_attributes"

module Audited
  class RequestStore < ActiveSupport::CurrentAttributes
    attribute :audited_store
  end
end
