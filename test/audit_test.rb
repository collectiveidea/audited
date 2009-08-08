require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class AuditTest < Test::Unit::TestCase
  def setup
    @user = User.new :name => "testing"
    @audit = Audit.new
  end

  context "user=" do
    should "be able to set the user to a model object" do
      @audit.user = @user
      @audit.user.should == @user
    end

    should "be able to set the user to nil" do
      @audit.user_id = 1
      @audit.user_type = 'User'
      @audit.username = 'joe'

      @audit.user = nil

      @audit.user.should == nil
      @audit.user_id.should == nil
      @audit.user_type.should == nil
      @audit.username.should == nil
    end

    should "be able to set the user to a string" do
      @audit.user = 'testing'
      @audit.user.should == 'testing'
    end

    should "clear model when setting to a string" do
      @audit.user = @user
      @audit.user = 'testing'
      @audit.user_id.should be(nil)
      @audit.user_type.should be(nil)
    end

    should "clear the username when setting to a model" do
      @audit.username = 'testing'
      @audit.user = @user
      @audit.username.should be(nil)
    end

  end
  
  context "revision" do
    should "recreate attributes" do
      user = User.create :name => "1"
      5.times {|i| user.update_attribute :name, (i + 2).to_s  }
      user.audits.each do |audit|
        audit.revision.name.should == audit.version.to_s
      end
    end
  
    should "set protected attributes" do
      u = User.create(:name => 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      u.audits[2].revision.logins.should == 2
      u.audits[1].revision.logins.should == 1
      u.audits[0].revision.logins.should == 0
    end
    
    should "bypass attribute assignment wrappers" do
      u = User.create(:name => '<Joe>')
      u.audits.first.revision.name.should == '&lt;Joe&gt;'
    end
    
    should "work for deleted records" do
      user = User.create :name => "1"
      user.destroy
      revision = user.audits.last.revision
      revision.name.should == user.name
      revision.new_record?.should be(true)
    end
  end
  
  should "set the version number on create" do
    user = User.create! :name => "Set Version Number"
    user.audits.first.version.should == 1
    user.update_attribute :name, "Set to 2"
    user.audits(true).first.version.should == 1
    user.audits(true).last.version.should == 2
    user.destroy
    user.audits(true).last.version.should == 3
  end

  context "reconstruct_attributes" do
    should "work with with old way of storing just the new value" do
      audits = Audit.reconstruct_attributes([Audit.new(:changes => {'attribute' => 'value'})])
      audits['attribute'].should == 'value'
    end
  end

  context "audited_classes" do
    class CustomUser < ActiveRecord::Base
    end
    class CustomUserSubclass < CustomUser
      acts_as_audited
    end

    should "include audited classes" do
      Audit.audited_classes.should include(User)
    end

    should "include subclasses" do
      Audit.audited_classes.should include(CustomUserSubclass)
    end
  end

  context "new_attributes" do
    should "return a hash of the new values" do
      Audit.new(:changes => {:a => [1, 2], :b => [3, 4]}).new_attributes.should == {'a' => 2, 'b' => 4}
    end
  end

  context "old_attributes" do
    should "return a hash of the old values" do
      Audit.new(:changes => {:a => [1, 2], :b => [3, 4]}).old_attributes.should == {'a' => 1, 'b' => 3}
    end
  end

  context "as_user" do
    setup do
      @user = User.create :name => 'testing'
    end

    should "record user objects" do
      Audit.as_user(@user) do
        company = Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.user.should == @user
        end
      end
    end

    should "record usernames" do
      Audit.as_user(@user.name) do
        company = Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.username.should == @user.name
        end
      end
    end

    should "be thread safe" do
      begin
        t1 = Thread.new do
          Audit.as_user(@user) do
            sleep 1
            Company.create(:name => 'The Auditors, Inc').audits.first.user.should == @user
          end
        end

        t2 = Thread.new do
          Audit.as_user(@user.name) do
            Company.create(:name => 'The Competing Auditors, LLC').audits.first.username.should == @user.name
            sleep 0.5
          end
        end

        t1.join
        t2.join
      rescue ActiveRecord::StatementInvalid
        STDERR.puts "Thread safety tests cannot be run with SQLite"
      end
    end
  end

end
