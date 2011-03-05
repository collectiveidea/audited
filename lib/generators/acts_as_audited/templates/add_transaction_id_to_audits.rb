class <%= migration_class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :transaction_id, :string

    add_index :audits, :transaction_id
  end

  def self.down
    remove_column :audits, :transaction_id

    remove_index :audits, :transaction_id
  end
end
