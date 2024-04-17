# frozen_string_literal: true

class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :<%= options[:audited_user_id_column_type] %>
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :<%= options[:audited_changes_column_type] %>
      t.column :version, :integer, :default => 0
      t.column :comment, :string
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :created_at, :datetime
    end

    add_index :audits, [:auditable_type, :auditable_id, :version], :name => 'auditable_index'
    add_index :audits, [:user_id, :user_type], :name => 'user_index'
    add_index :audits, :request_uuid
    add_index :audits, :created_at

    create_table :audit_associations, :force => true do |t|
      t.column :audit_id, :integer
      t.column :associated_id, :integer
      t.column :associated_type, :string
    end

    add_index :audit_associations, :audit_id, :name => 'index_audit_associations_on_audit_id'
    add_index :audit_associations, [:associated_type, :associated_id], :name => 'index_audit_associations_on_associated'
  end

  def self.down
    drop_table :audit_associations
    drop_table :audits
  end
end
