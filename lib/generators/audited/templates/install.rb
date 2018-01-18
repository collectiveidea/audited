class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    table = "<%= options[:audited_audit_table_name] %>"
    create_table table, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :associated_id, :integer
      t.column :associated_type, :string
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

    add_index table, [:auditable_type, :auditable_id], :name => 'auditable_index'
    add_index table, [:associated_type, :associated_id], :name => 'associated_index'
    add_index table, [:user_id, :user_type], :name => 'user_index'
    add_index table, :request_uuid
    add_index table, :created_at
  end

  def self.down
    table = "<%= options[:audited_audit_table_name] %>"
    drop_table table
  end
end
