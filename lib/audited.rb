module Audited
  VERSION = '3.0.0'

  class << self
    attr_accessor :ignored_attributes, :current_user_method, :audit_class
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user
end
