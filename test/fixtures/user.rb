class User < ActiveRecord::Base
  acts_as_audited :except => :password
end