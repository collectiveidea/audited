module AuditedSpecHelpers

  def create_user(attrs = {})
    User.create({:name => 'Brandon', :username => 'brandon', :password => 'password'}.merge(attrs))
  end

  def create_versions(n = 2)
    User.create(:name => 'Foobar 1').tap do |u|
      (n - 1).times do |i|
        u.update_attribute :name, "Foobar #{i + 2}"
      end
      u.reload
    end
  end

end
