require 'active_record'
require 'logger'

begin
  db_config = ActiveRecord::Base.configurations[Rails.env].clone
  db_type = db_config['adapter']
  db_name = db_config.delete('database')
  raise Exception.new('No database name specified.') if db_name.blank?
  if db_type == 'sqlite3'
    db_file = Pathname.new(__FILE__).dirname.join(db_name)
    db_file.unlink if db_file.file?
  else
    if defined?(JRUBY_VERSION)
      db_config.symbolize_keys! 
      db_config[:configure_connection] = false 
    end
    adapter = ActiveRecord::Base.send("#{db_type}_connection", db_config)
    adapter.recreate_database db_name
    adapter.disconnect!
  end
rescue Exception => e
  Kernel.warn e
end

logfile = Pathname.new(__FILE__).dirname.join('debug.log')
logfile.unlink if logfile.file?
ActiveRecord::Base.logger = Logger.new(logfile)

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.column :name, :string
    t.column :username, :string
    t.column :password, :string
    t.column :activated, :boolean
    t.column :suspended_at, :datetime
    t.column :logins, :integer, :default => 0
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end

  create_table :companies do |t|
    t.column :name, :string
    t.column :owner_id, :integer
  end

  create_table :authors do |t|
    t.column :name, :string
  end

  create_table :books do |t|
    t.column :authord_id, :integer
    t.column :title, :string
  end

  create_table :audits do |t|
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

  add_index :audits, [:auditable_id, :auditable_type], :name => 'auditable_index'
  add_index :audits, [:associated_id, :associated_type], :name => 'associated_index'
  add_index :audits, [:user_id, :user_type], :name => 'user_index'
  add_index :audits, :request_uuid
  add_index :audits, :created_at
end
