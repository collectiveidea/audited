# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :audit_trails, :association_id, :integer
    add_column :audit_trails, :association_type, :string
  end

  def self.down
    remove_column :audit_trails, :association_type
    remove_column :audit_trails, :association_id
  end
end
