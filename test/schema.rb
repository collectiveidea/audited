ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :username, :string
    t.column :password, :string
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  
  create_table :audits, :force => true do |t|
    t.column :auditable_id, :integer
    t.column :auditable_type, :string
    t.column :user_id, :integer
    t.column :action, :string
    t.column :changes, :text
    t.column :created_at, :datetime
  end
end