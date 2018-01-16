ActiveRecord::Schema.define do
  create_table :audits, :force => true do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :associated_id, :integer
    t.column :associated_type, :string
    t.column :user_id, :integer
    t.column :user_type, :string
    t.column :username, :string
    t.column :action, :string
    t.column :audited_changes, :text
    t.column :version, :integer, :default => 0
    t.column :comment, :string
    t.column :remote_address, :string
    t.column :request_uuid, :string
    t.column :created_at, :datetime
  end

  drop_table :audited_audit_associates if table_exists?(:audited_audit_associates)
end
