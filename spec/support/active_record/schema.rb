require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.logger = Logger.new(SPEC_ROOT.join('debug.log'))
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
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
    t.column :owner_id, :integer
  end

  create_table :authors, :force => true do |t|
    t.column :name, :string
  end

  create_table :books, :force => true do |t|
    t.column :authord_id, :integer
    t.column :title, :string
  end

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
    t.column :created_at, :datetime
  end

  add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
  add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
  add_index :audits, [:user_id, :user_type], :name => 'user_index'
  add_index :audits, :created_at
end
