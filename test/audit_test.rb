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

  should "revision" do
    user = User.create :name => "1"
    5.times {|i| user.update_attribute :name, (i + 2).to_s  }
    user.audits.each do |audit|
      audit.revision.name.should == audit.version.to_s
    end
  end

  should "be able to create revision for deleted records" do
    user = User.create :name => "1"
    user.destroy
    revision = user.audits.last.revision
    revision.name.should == user.name
    revision.new_record?.should be(true)
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

  context "parent record tracking" do
    class ::Author < ActiveRecord::Base
      has_many :books
    end
    class ::Book < ActiveRecord::Base
      belongs_to :author
      acts_as_audited :parent => :author
    end

    setup do
      @author = Author.create!( :name => 'Kenneth Kalmer' )
      @book = Book.create!( :title => 'Open Sourcery 101', :author => @author )
    end

    should "give parents access to child changes" do
      assert_respond_to @author, :book_audits
      assert_respond_to @author, :child_record_audits
    end

    should "allow detection of audited parent" do
      assert_respond_to @author, :audited_parent?
    end

    should "track the parent in child audits" do
      assert_equal @book.audits.first.auditable_parent, @author
      assert_equal @author.book_audits.first.auditable, @book

      assert_equal @author.child_record_audits, @author.book_audits
    end
  end

end
