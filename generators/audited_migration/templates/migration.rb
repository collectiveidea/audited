class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :auditable_parent_id, :integer
      t.column :auditable_parent_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :changes, :text
      t.column :audit_version, :integer, :default => 0
      t.column :comment, :string
      t.column :created_at, :datetime
    end
    
    add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
    add_index :audits, [:auditable_parent_id, :auditable_parent_type], :name => 'auditable_parent_index'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :created_at  
  end

  def self.down
    drop_table :audits
  end
end
