require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Audited" do
  before do
    @user = User.new :name => "testing"
    @audit = Audit.new :user => @user
  end

  it "set user attribute to a model object" do
    @audit.user.should == @user
  end

  it "set user to nil" do
    # test_set_user_to_model
    @audit.user = nil
    @audit.user.should == nil
    @audit[:user_id].should == nil
    @audit[:user_type].should == nil
    @audit[:username].should == nil
  end
  
  it "set user to string" do
    @audit = Audit.new :user => "testing"
    @audit.user.should == "testing"
  end
  
  it "set to string then model object" do
    @user = User.new :name => "testing"
    @audit = Audit.new :user => "testing"
    @audit.user = @user
    @audit.user.should == @user
    @audit.username.should == nil
  end
  
  it "revision" do
    user = User.create :name => "1"
    5.times {|i| user.update_attribute :name, (i + 2).to_s  }
    user.audits.each do |audit|
      audit.revision.name.should == audit.version.to_s
    end
  end

  it "revision for deleted model" do
    user = User.create :name => "1"
    user.destroy
    revision = user.audits.last.revision
    revision.name.should == user.name
    revision.new_record?.should_not == nil
  end
  
  it "sets version number on create" do
    user = User.create! :name => "Set Version Number"
    user.audits.last.version.should == 1
    user.update_attribute :name, "Set to 2"
    user.audits(true).first.version.should == 2
    user.audits(true).last.version.should == 1
    user.destroy
    user.audits(true).first.version.should == 3
  end

end