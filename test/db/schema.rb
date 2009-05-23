ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :username, :string
    t.column :password, :string
    t.column :activated, :boolean
    t.column :logins, :integer, :default => 0
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end
  
  create_table :audits, :force => true do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :user_id, :integer
    t.column :user_type, :string
    t.column :username, :string
    t.column :action, :string
    t.column :changes, :text
    t.column :version, :integer, :default => 0
    t.column :created_at, :datetime
  end
  
  add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
  add_index :audits, [:user_id, :user_type], :name => 'user_index'
  add_index :audits, :created_at  
end