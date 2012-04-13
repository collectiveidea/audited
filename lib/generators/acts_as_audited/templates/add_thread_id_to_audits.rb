class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :thread_id, :integer, :limit => 8
    add_index :audits, :thread_id
  end

  def self.down
    remove_index :audits, :thread_id
    remove_column :audits, :thread_id
  end
end

