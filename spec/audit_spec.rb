require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Audit do
  before do
    @user = User.new :name => "testing"
    @audit = Audit.new
  end

  describe "user=" do
    it "should be able to set the user to a model object" do
      @audit.user = @user
      @audit.user.should == @user
    end
    
    it "should be able to set the user to nil" do
      @audit.user_id = 1
      @audit.user_type = 'User'
      @audit.username = 'joe'

      @audit.user = nil

      @audit.user.should == nil
      @audit.user_id.should == nil
      @audit.user_type.should == nil
      @audit.username.should == nil
    end
    
    it "should be able to set the user to a string" do
      @audit.user = 'testing'
      @audit.user.should == 'testing'
    end

    it "should clear model when setting to a string" do
      @audit.user = @user
      @audit.user = 'testing'
      @audit.user_id.should be_nil
      @audit.user_type.should be_nil
    end

    it "should clear the username when setting to a model" do
      @audit.username = 'testing'
      @audit.user = @user
      @audit.username.should be_nil
    end

  end

  it "revision" do
    user = User.create :name => "1"
    5.times {|i| user.update_attribute :name, (i + 2).to_s  }
    user.audits.each do |audit|
      audit.revision.name.should == audit.version.to_s
    end
  end

  it "should be able to create revision for deleted records" do
    user = User.create :name => "1"
    user.destroy
    revision = user.audits.last.revision
    revision.name.should == user.name
    revision.should be_new_record
  end
  
  it "should set the version number on create" do
    user = User.create! :name => "Set Version Number"
    user.audits.first.version.should == 1
    user.update_attribute :name, "Set to 2"
    user.audits(true).first.version.should == 1
    user.audits(true).last.version.should == 2
    user.destroy
    user.audits(true).last.version.should == 3
  end
  
  describe "reconstruct_attributes" do
    it "should work with with old way of storing just the new value" do
      audits = Audit.reconstruct_attributes([Audit.new(:changes => {'attribute' => 'value'})])
      audits['attribute'].should == 'value'
    end
  end

end