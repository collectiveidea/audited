<%- table_name = options[:audited_table_name].underscore.pluralize -%>
class <%= migration_class_name %> < <%= migration_parent %>
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :associated_id, :integer
      t.column :associated_type, :string
      t.column :user_id, :<%= options[:audited_user_id_column_type] %>
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :<%= options[:audited_changes_column_type] %>
      t.column :version, :integer, default: 0
      t.column :comment, :string
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :audited_context, :<%= options[:audited_context_column_type] %>
      t.column :created_at, :datetime
    end

    add_index :<%= table_name %>, [:auditable_type, :auditable_id, :version], name: "<%= table_name %>_auditable_index"
    add_index :<%= table_name %>, [:associated_type, :associated_id], name: "<%= table_name %>_associated_index"
    add_index :<%= table_name %>, [:user_id, :user_type], name: "<%= table_name %>_user_index"
    add_index :<%= table_name %>, :request_uuid
    add_index :<%= table_name %>, :created_at
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
