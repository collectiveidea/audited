# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    change_column_null :audits, :action, false
    change_column_null :audits, :audited_changes, false
    change_column_null :audits, :version, false
    change_column_null :audits, :created_at, false
  end

  def self.down
    change_column_null :audits, :action, true
    change_column_null :audits, :audited_changes, true
    change_column_null :audits, :version, true
    change_column_null :audits, :created_at, true
  end
end
