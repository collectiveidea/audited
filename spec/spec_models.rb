require 'cgi'

class User < ActiveRecord::Base
  acts_as_audited :except => :password

  attr_protected :logins

  def name=(val)
    write_attribute(:name, CGI.escapeHTML(val))
  end
end

class BlankUser < ActiveRecord::Base
  set_table_name :users
end

class CommentRequiredUser < ActiveRecord::Base
  set_table_name :users
  acts_as_audited :comment_required => true
end

class UnprotectedUser < ActiveRecord::Base
  set_table_name :users
  acts_as_audited :protect => false
  attr_accessible :name, :username, :password
end

class AccessibleUser < ActiveRecord::Base
  set_table_name :users
  attr_accessible :name, :username, :password # declare attr_accessible before calling aaa
  acts_as_audited
end

class NoAttributeProtectionUser < ActiveRecord::Base
  set_table_name :users
  acts_as_audited
end

class Company < ActiveRecord::Base
  acts_as_audited
end

class Owner < ActiveRecord::Base
  set_table_name 'users'
  has_associated_audits
end

class OwnedCompany < ActiveRecord::Base
  set_table_name 'companies'
  belongs_to :owner, :class_name => "Owner"
  attr_accessible :name, :owner # declare attr_accessible before calling aaa
  acts_as_audited :associated_with => :owner
end

class OnUpdateDestroy < ActiveRecord::Base
  set_table_name 'companies'
  acts_as_audited :on => [:update, :destroy]
end

class OnCreateDestroy < ActiveRecord::Base
  set_table_name 'companies'
  acts_as_audited :on => [:create, :destroy]
end

class OnCreateDestroyExceptName < ActiveRecord::Base
  set_table_name 'companies'
  acts_as_audited :except => :name, :on => [:create, :destroy]
end

class OnCreateUpdate < ActiveRecord::Base
  set_table_name 'companies'
  acts_as_audited :on => [:create, :update]
end

class ActiveSupport::TestCase
  #def change(receiver=nil, message=nil, &block)
  #  ChangeExpectation.new(self, receiver, message, &block)
  #end

  def create_user(attrs = {})
    User.create({:name => 'Brandon', :username => 'brandon', :password => 'password'}.merge(attrs))
  end

  def create_versions(n = 2)
    returning User.create(:name => 'Foobar 1') do |u|
      (n - 1).times do |i|
        u.update_attribute :name, "Foobar #{i + 2}"
      end
      u.reload
    end
  end
end
