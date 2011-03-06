class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :tag, :string

    add_index :audits, :tag
  end

  def self.down
    remove_column :audits, :tag

    remove_index :audits, :tag
  end
end
