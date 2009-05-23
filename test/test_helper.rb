ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view'
require 'test/unit'
require 'shoulda'
require 'matchy'
require File.dirname(__FILE__) + '/../init.rb'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/db/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3mem'])
ActiveRecord::Migration.verbose = false
load(File.dirname(__FILE__) + "/db/schema.rb")

class User < ActiveRecord::Base
  acts_as_audited :except => :password
end
class Company < ActiveRecord::Base
end

class Test::Unit::TestCase
  def change(receiver=nil, message=nil, &block)
    ChangeExpectation.new(self, receiver, message, &block)
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

# Change matcher copied from RSpec
class ChangeExpectation < Matchy::Expectations::Base
  def initialize(test_case, receiver=nil, message=nil, &block)
    @test_case = test_case
    @message = message || "result"
    @value_proc = block || lambda {receiver.__send__(message)}
    @to = @from = @minimum = @maximum = @amount = nil
  end
  
  def matches?(event_proc)
    raise_block_syntax_error if block_given?
    
    @before = evaluate_value_proc
    event_proc.call
    @after = evaluate_value_proc
    
    return (@to = false) if @from unless @from == @before
    return false if @to unless @to == @after
    return (@before + @amount == @after) if @amount
    return ((@after - @before) >= @minimum) if @minimum
    return ((@after - @before) <= @maximum) if @maximum        
    return @before != @after
  end
  
  def raise_block_syntax_error
    raise(<<-MESSAGE
block passed to should or should_not change must use {} instead of do/end
MESSAGE
    )
  end
  
  def evaluate_value_proc
    @value_proc.call
  end
  
  def failure_message
    if @to
      "#{@message} should have been changed to #{@to.inspect}, but is now #{@after.inspect}"
    elsif @from
      "#{@message} should have initially been #{@from.inspect}, but was #{@before.inspect}"
    elsif @amount
      "#{@message} should have been changed by #{@amount.inspect}, but was changed by #{actual_delta.inspect}"
    elsif @minimum
      "#{@message} should have been changed by at least #{@minimum.inspect}, but was changed by #{actual_delta.inspect}"
    elsif @maximum
      "#{@message} should have been changed by at most #{@maximum.inspect}, but was changed by #{actual_delta.inspect}"
    else
      "#{@message} should have changed, but is still #{@before.inspect}"
    end
  end
  
  def actual_delta
    @after - @before
  end
  
  def negative_failure_message
    "#{@message} should not have changed, but did change from #{@before.inspect} to #{@after.inspect}"
  end
  
  def by(amount)
    @amount = amount
    self
  end
  
  def by_at_least(minimum)
    @minimum = minimum
    self
  end
  
  def by_at_most(maximum)
    @maximum = maximum
    self
  end      
  
  def to(to)
    @to = to
    self
  end
  
  def from (from)
    @from = from
    self
  end
  
  def description
    "change ##{@message}"
  end
end
