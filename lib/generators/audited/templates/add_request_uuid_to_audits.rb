# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :audit_trails, :request_uuid, :string
    add_index :audit_trails, :request_uuid
  end

  def self.down
    remove_column :audit_trails, :request_uuid
  end
end
