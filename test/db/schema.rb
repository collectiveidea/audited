ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :username, :string
    t.column :password, :string
    t.column :activated, :boolean
    t.column :suspended_at, :datetime
    t.column :logins, :integer, :default => 0
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end

  create_table :profiles, :force => true do |t|
    t.column :email, :string
  end

  [:audits, :audit_profiles].each do |a|
    create_table a, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :changes, :text
      t.column :version, :integer, :default => 0
      t.column :comment, :string
      t.column :created_at, :datetime
    end
    
    add_index a, [:auditable_id, :auditable_type]
    add_index a, [:user_id, :user_type]
    add_index a, :created_at
  end
end
