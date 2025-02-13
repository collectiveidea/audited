require "active_record"
require "logger"

begin
  if ActiveRecord.version >= Gem::Version.new("6.1.0")
    db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    ActiveRecord::Tasks::DatabaseTasks.create(db_config)
  else
    db_config = ActiveRecord::Base.configurations[Rails.env].clone
    db_type = db_config["adapter"]
    db_name = db_config.delete("database")
    raise StandardError.new("No database name specified.") if db_name.blank?
    if db_type == "sqlite3"
      db_file = Pathname.new(__FILE__).dirname.join(db_name)
      db_file.unlink if db_file.file?
    else
      if defined?(JRUBY_VERSION)
        db_config.symbolize_keys!
        db_config[:configure_connection] = false
      end
      adapter = ActiveRecord::Base.send("#{db_type}_connection", db_config)
      adapter.recreate_database db_name, db_config.slice("charset").symbolize_keys
      adapter.disconnect!
    end
  end
rescue => e
  Kernel.warn e
end

logfile = Pathname.new(__FILE__).dirname.join("debug.log")
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
    t.column :status, :integer, default: 0
    t.column :suspended_at, :datetime
    t.column :logins, :integer, default: 0
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :favourite_device, :string
    t.column :ssn, :integer
    t.column :phone_numbers, :string
  end

  create_table :companies do |t|
    t.column :name, :string
    t.column :owner_id, :integer
    t.column :type, :string
  end

  create_table :authors do |t|
    t.column :name, :string
  end

  create_table :books do |t|
    t.column :authord_id, :integer
    t.column :title, :string
  end

  def create_audits_table(table_name)
    create_table table_name do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :associated_id, :integer
      t.column :associated_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :username, :string
      t.column :action, :string
      t.column :audited_changes, :text
      t.column :version, :integer, default: 0
      t.column :comment, :string
      t.column :remote_address, :string
      t.column :request_uuid, :string
      t.column :created_at, :datetime
    end

    add_index table_name, [:auditable_id, :auditable_type]
    add_index table_name, [:associated_id, :associated_type]
    add_index table_name, [:user_id, :user_type]
    add_index table_name, :request_uuid
    add_index table_name, :created_at
  end

  create_audits_table :audits
  create_audits_table :custom_audits
end
