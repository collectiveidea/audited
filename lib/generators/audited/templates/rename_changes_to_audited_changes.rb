# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    rename_column :audit_trails, :changes, :audited_changes
  end

  def self.down
    rename_column :audit_trails, :audited_changes, :changes
  end
end
