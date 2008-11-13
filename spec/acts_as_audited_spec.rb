require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActsAsAudited" do
  
  it "acts as authenticated declaration includes instance methods" do
    User.new.should be_kind_of(CollectiveIdea::Acts::Audited::InstanceMethods)
  end
  
  it "acts as authenticated declaration extends singleton methods" do
    User.should be_kind_of(CollectiveIdea::Acts::Audited::SingletonMethods)
  end

  it "audits attributes" do
    attrs = {'name' => nil, 'username' => nil, 'logins' => 0, 'activated' => nil}
    User.new.audited_attributes.should == attrs
  end
  
  it "has columns not audited by default" do
    ['created_at', 'updated_at', 'lock_version', 'id', 'password'].each do |column|
      User.non_audited_columns.should include(column)
    end
  end

  it "doesn't save non audited columns" do
    u = create_user
    u.audits.first.changes.keys.any?{|col| ['created_at', 'updated_at', 'password'].include? col}.should be_false
  end
  
  it "audits saves and updates" do
    u = nil
    assert_difference(Audit, :count)    { u = create_user }
    assert_difference(Audit, :count)    { u.update_attribute(:name, "Someone") }
    assert_difference(Audit, :count)    { u.update_attribute(:name, "Someone else") }
    assert_no_difference(Audit, :count) { u.save }
    assert_difference(Audit, :count)    { u.destroy }
  end
  
  it "audits creates" do
    u = User.create! :name => 'Brandon'
    u.audits.count.should == 1
    audit = u.audits.first
    audit.action.should == 'create'
    audit.changes.should == u.audited_attributes
  end
  
  it "audits updates" do
    u = create_user
    u.update_attributes :name => 'Changed'
    u.audits.count.should == 2
    u.reload
    audit = u.audits.first
    audit.action.should == 'update'
    audit.changes.should == {'name' => 'Changed'}
  end

  it "audits destroys" do
    u = create_user
    u.destroy
    u.audits.count.should == 2
    audit = u.audits.first
    audit.action.should == 'destroy'
    audit.changes.should == nil
  end
  
  it "can save without auditing" do
    assert_no_difference Audit, :count do
      u = User.new(:name => 'Brandon')
      u.save_without_auditing.should_not == nil
    end
  end
  
  it "can do stuff in a block without auditing" do
    assert_no_difference Audit, :count do
      User.without_auditing { User.create(:name => 'Brandon') }
    end
  end
  
  it "leverages ARs dirty attribute tracking, aka 'changed?'" do
    u = create_user
    u.changed?.should_not be_true
    u.name = "Bobby"
    u.changed?.should_not be_nil
    u.name_changed?.should_not be_nil
    u.username_changed?.should_not be_true
  end
  
  it "clears changed attributes after save" do
    u = User.new(:name => 'Brandon')
    u.changed?.should_not be_nil
    u.save
    u.changed?.should_not be_true
  end
  
  it "type casting" do
    pending
    User.delete_all; Audit.delete_all
    u = create_user(:logins => 0, :activated => true)
    u.update_attribute :logins, '0' 
    assert_no_difference(Audit, :count) {
      puts "User count before: #{User.count}; Audit count before: #{Audit.count}"
      u.update_attribute :logins, '0'
      u.update_attribute :logins, '0' 
      
      puts "User count after: #{User.count}; Audit count after: #{Audit.count}"
    }
    # assert_no_difference(Audit, :count) { u.update_attribute :logins, 0 }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, true }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, 1 }
  end
  
  it "stores changes in a hash" do
    audit = create_user.audits.first
    audit.reload
    audit.changes.should be_an_instance_of(Hash)
  end
  
  it "save without modifications" do
    u = create_user
    u.reload
    
    lambda{
      u.changed?.should_not be_true
      u.save!
    }.should_not raise_error
  end
  
  it "returns revisions as an Array of Users" do
    u = create_versions
    u.revisions.should be_an_instance_of(Array)
    u.revisions.each {|version| 
      version.should be_an_instance_of(User)
    }
  end
  
  it "the first revision is the most recent one" do
    u = User.create(:name => 'Brandon')
    u.revisions.size.should == 1
    u.revisions[0].name.should == 'Brandon'
    
    u.update_attribute :name, 'Foobar'
    u.revisions.size.should == 2
    u.revisions[0].name.should == 'Foobar'
    u.revisions[1].name.should == 'Brandon'
  end
  
  # TODO: not sure what this actually tests
  it "revisions without changes" do
    u = User.create
    lambda{
      u.revisions.size.should == 1
    }.should_not raise_error
  end
  
  # FIXME: figure out a better way to test this
  it "can reconstruct the object as it was at a certain time ('revision_at')" do
    u = create_user
    Audit.update(u.audits.first.id, :created_at => 1.hour.ago)
    u.update_attributes :name => 'updated'
    u.revision_at(2.minutes.ago).version.should == 1
  end
  
  it "doesn't have a revision from a point in time before the creation (nil)" do
    u = create_user
    u.revision_at(1.week.ago).should be_nil
  end
  
  it "can get specific revision" do
    u = create_versions(5)
    revision = u.revision(3)
    revision.should be_an_instance_of(User)
    revision.version.should == 3
    revision.name.should == 'Foobar 3'
  end
  
  it "can get previous revisions" do
    u = create_versions(5)
    revision = u.revision(:previous)
    revision.version.should == 4
    revision.should == u.revision(4)
  end

  it "get previous revision repeatedly" do
    u = create_versions(5).revision(:previous)
    u.version.should == 4
    u.revision(:previous).version.should == 3
  end
  
  it "revision marks attributes changed" do
    u = create_versions(2)
    u.revision(1).name_changed?.should_not be_nil
  end

  it "save revision records audit" do
    u = create_versions(2)
    assert_difference Audit, :count do
      u.revision(1).save.should_not be_nil
    end
  end
  
  it "an AR record can live without previous audits without raising" do
    user = create_user
    user.audits.destroy_all
    lambda{
      user.revision(:previous)
    }.should_not raise_error(NoMethodError)
    # assert_nothing_raised(NoMethodError) { user.revision(:previous) }
  end
  
  it "can update stuff without auditing if needed" do
    u = create_user
    assert_no_difference Audit, :count do
      User.without_auditing do
        u.update_attribute :name, 'Changed'
      end
    end
    
    assert_difference Audit, :count do
      u.update_attribute :name, 'Changed Again'
    end
  end

  describe "can disable auditing callbacks" do
    before do
      User.disable_auditing_callbacks
    end
    
    after do
      User.enable_auditing_callbacks
    end
    
    it "disable auditing callbacks" do
      assert_no_difference Audit, :count do
        create_user
      end
    end
  end
  
  class InaccessibleUser < ActiveRecord::Base
    set_table_name :users
    acts_as_audited
    attr_accessible :name, :username, :password
  end

  # TODO: not sure what this tests
  it "attr accessible breaks" do
    lambda{
      InaccessibleUser.new(:name => 'FAIL!')
    }.should raise_error(RuntimeError)
  end
  
  class UnprotectedUser < ActiveRecord::Base
    set_table_name :users
    acts_as_audited :protect => false
    attr_accessible :name, :username, :password
  end
  it "attr accessible without protection" do
    lambda{
      UnprotectedUser.new(:name => 'NO FAIL!')
    }.should_not raise_error(RuntimeError)
    
  end
  
  # declare attr_accessible before calling aaa
  class AccessibleUser < ActiveRecord::Base
    set_table_name :users
    attr_accessible :name, :username, :password
    acts_as_audited
  end
  
  it "attr accessible without protection" do
    lambda{
      AccessibleUser.new(:name => 'NO FAIL!')
    }.should_not raise_error
  end
  
end
