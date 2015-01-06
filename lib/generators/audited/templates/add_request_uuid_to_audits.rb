class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :request_uuid, :string
    add_index :audits, :request_uuid
  end

  def self.down
    remove_column :audits, :request_uuid
  end
end
