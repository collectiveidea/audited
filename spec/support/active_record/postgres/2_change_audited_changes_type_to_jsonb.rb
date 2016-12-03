class ChangeAuditedChangesTypeToJsonb < ActiveRecord::Migration
  def self.up
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :jsonb
  end

  def self.down
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :text
  end
end
