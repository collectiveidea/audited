class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :user_agent, :string
    add_index :audits, :user_agent
  end

  def self.down
    remove_column :audits, :user_agent
  end
end
