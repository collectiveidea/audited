class ChangeAuditedChangesTypeToJson < ActiveRecord::Migration
  def self.up
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :json
  end

  def self.down
    remove_column :audits, :audited_changes
    add_column :audits, :audited_changes, :text
  end
end
