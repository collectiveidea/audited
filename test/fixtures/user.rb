
class User < ActiveRecord::Base
  acts_as_audited :except => :password
  
  def self.current_user
  end
end