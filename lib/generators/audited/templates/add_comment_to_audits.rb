# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    add_column :audit_trails, :comment, :string
  end

  def self.down
    remove_column :audit_trails, :comment
  end
end
