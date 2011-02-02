class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    rename_column :audits, :changes, :audited_changes
  end

  def self.down
    rename_column :audits, :audited_changes, :changes
  end
end
