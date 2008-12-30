ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'active_record'
require 'action_controller'
require 'action_view'
require File.dirname(__FILE__) + '/../init.rb'

require 'active_record/fixtures'
require 'action_controller/test_process'

require 'spec'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3mem'])

ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/schema.rb")

class User < ActiveRecord::Base
  acts_as_audited :except => :password
end
class Company < ActiveRecord::Base
end


Spec::Runner.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  # config.fixture_path = '/spec/fixtures/'
  
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

