ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'multi_rails_init'
require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view'
require 'test/unit'
require 'shoulda'

gem 'jnunemaker-matchy'
require 'matchy'
require File.dirname(__FILE__) + '/../init.rb'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/db/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3mem'])
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/db/schema.rb")

class User < ActiveRecord::Base
  acts_as_audited :except => :password
  
  attr_protected :logins
  
  def name=(val)
    write_attribute(:name, CGI.escapeHTML(val))
  end
end
class Company < ActiveRecord::Base
  acts_as_audited
end

class Test::Unit::TestCase
  # def change(receiver=nil, message=nil, &block)
  #   ChangeExpectation.new(self, receiver, message, &block)
  # end
  
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
