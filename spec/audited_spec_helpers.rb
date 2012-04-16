module AuditedSpecHelpers

  def create_user(use_mongo = false, attrs = {})
    klass = use_mongo ? Models::MongoMapper::User : Models::ActiveRecord::User
    klass.create({:name => 'Brandon', :username => 'brandon', :password => 'password'}.merge(attrs))
  end

  def create_versions(n = 2, use_mongo = false)
    klass = use_mongo ? Models::MongoMapper::User : Models::ActiveRecord::User

    klass.create(:name => 'Foobar 1').tap do |u|
      (n - 1).times do |i|
        u.update_attribute :name, "Foobar #{i + 2}"
      end
      u.reload
    end
  end

  def create_active_record_user(attrs = {})
    create_user(false, attrs)
  end

  def create_mongo_user(attrs = {})
    create_user(true, attrs)
  end

  def create_mongo_versions(n = 2)
    create_versions(n, true)
  end

end
