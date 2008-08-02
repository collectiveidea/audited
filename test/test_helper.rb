$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'rubygems'
require 'multi_rails_init'
require 'active_record'
require 'action_controller'
require 'action_view'
require File.dirname(__FILE__) + '/../init.rb'

require 'active_record/fixtures'
require 'action_controller/test_process'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3mem'])

ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/schema.rb")

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

# load model
class User < ActiveRecord::Base
  acts_as_audited :except => :password
end
class Company < ActiveRecord::Base
end

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
  
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  # http://project.ioni.st/post/217#post-217
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end
  
  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end

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