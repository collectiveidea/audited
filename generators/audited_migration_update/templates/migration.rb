class <%= class_name %> < ActiveRecord::Migration
  def self.up
    add_column :audits, :comment, :string
  end

  def self.down
    remove_column :audits, :comment
  end
end
