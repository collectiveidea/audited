require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CollectiveIdea::Acts::Audited do
  
  it "should include instance methods" do
    User.new.should be_kind_of(CollectiveIdea::Acts::Audited::InstanceMethods)
  end
  
  it "should extend singleton methods" do
    User.should be_kind_of(CollectiveIdea::Acts::Audited::SingletonMethods)
  end

  ['created_at', 'updated_at', 'lock_version', 'id', 'password'].each do |column|
    it "should not audit #{column}" do
      User.non_audited_columns.should include(column)
    end
  end

  it "should not save non-audited columns" do
    create_user.audits.first.changes.keys.any?{|col| ['created_at', 'updated_at', 'password'].include? col}.should be_false
  end
  
  describe "on create" do
    it "should save an audit" do
      lambda {
        create_user.should have(1).audit
      }.should change { Audit.count }.by(1)
    end
    
    it "should set the action to 'create'" do
      audit = create_user.audits.first
      audit.action.should == 'create'
    end
    
    it "should store all the audited attributes" do
      user = User.create(:name => 'Brandon')
      user.audits.first.changes.should == user.audited_attributes
    end
  end
  
  describe "on update" do
    before do
      @user = create_user(:name => 'Brandon')
    end
    
    it "should save an audit on update" do
      lambda { @user.update_attribute(:name, "Someone") }.should change { @user.audits.count }.by(1)
      lambda { @user.update_attribute(:name, "Someone else") }.should change { @user.audits.count }.by(1)
    end

    it "should not save an audit if the record is not changed" do
      lambda { @user.save! }.should_not change { Audit.count }
    end
    
    it "should set the action to 'update'" do
      @user.update_attributes :name => 'Changed'
      @user.audits.last.action.should == 'update'
    end
    
    it "should store the changed attributes" do
      @user.update_attributes :name => 'Changed'
      @user.audits.last.changes.should == {'name' => ['Brandon', 'Changed']}
    end
    
    it "should not save an audit if the value doesn't change after type casting" do
      pending "Dirty tracking doesn't seem to account for type casting"
      @user.update_attributes! :logins => 0, :activated => true
      lambda { @user.update_attribute :logins, '0' }.should_not change { Audit.count }
      lambda { @user.update_attribute :activated, 1 }.should_not change { Audit.count }
      lambda { @user.update_attribute :activated, '1' }.should_not change { Audit.count }
    end
    
  end
  
  describe "on destroy" do
    before do
      @user = create_user
    end
    
    it "should save an audit" do
      lambda { @user.destroy }.should change { Audit.count }.by(1)
      @user.should have(2).audits
    end
    
    it "should set the action to 'destroy'" do
      @user.destroy
      @user.audits.last.action.should == 'destroy'
    end
    
    it "should store all of the audited attributes" do
      @user.destroy
      @user.audits.last.changes.should == @user.audited_attributes
    end
    
    it "should be able to reconstruct destroyed record without history" do
      @user.audits.delete_all
      @user.destroy
      revision = @user.audits.first.revision
      revision.name.should == @user.name
    end
  end
  
  describe "dirty tracking" do
    before do
      @user = create_user
    end
    
    it "should not be changed when the record is saved" do
      u = User.new(:name => 'Brandon')
      u.should be_changed
      u.save
      u.should_not be_changed
    end
    
    it "should be changed when an attribute has been changed" do
      @user.name = "Bobby"
      @user.should be_changed
      @user.name_changed?.should be_true
      @user.username_changed?.should be_false
    end
    
    it "should not be changed if the value doesn't change after type casting" do
      pending "Dirty tracking doesn't seem to account for type casting"
      @user.update_attributes! :logins => 0, :activated => true
      @user.logins = '0'
      @user.should_not be_changed
    end
    
  end
  
  describe "revisions" do
    before do
      @user = create_versions
    end
    
    it "should be an Array of Users" do
      @user.revisions.should be_an_instance_of(Array)
      @user.revisions.each {|version| version.should be_an_instance_of(User) }
    end
    
    it "should have one revision for a new record" do
      create_user.revisions.size.should == 1
    end
    
    it "should have one revision for each audit" do
      @user.should have(@user.audits.size).revisions
    end

    it "should set the attributes for each revision" do
      u = User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'
      
      u.revisions.size.should == 3

      u.revisions[0].name.should == 'Brandon'
      u.revisions[0].username.should == 'brandon'
      
      u.revisions[1].name.should == 'Foobar'
      u.revisions[1].username.should == 'brandon'

      u.revisions[2].name.should == 'Awesome'
      u.revisions[2].username.should == 'keepers'
    end
    
    it "should access to only recent revisions" do
      u = User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'
      
      u.revisions(2).size.should == 2

      u.revisions(2)[0].name.should == 'Foobar'
      u.revisions(2)[0].username.should == 'brandon'

      u.revisions(2)[1].name.should == 'Awesome'
      u.revisions(2)[1].username.should == 'keepers'
    end

    it "should be empty if no audits exist" do
      @user.audits.delete_all
      @user.revisions.should be_empty
    end

    it "should ignore attributes that have been deleted" do
      @user.audits.last.update_attributes :changes => {:old_attribute => 'old value'}
      lambda { @user.revisions }.should_not raise_error(ActiveRecord::UnknownAttributeError)
    end

  end
  
  describe "revision" do
    before do
      @user = create_versions(5)
    end
    
    it "should maintain identity" do
      @user.revision(1).should == @user
    end
    
    it "should find the given revision" do
      revision = @user.revision(3)
      revision.should be_an_instance_of(User)
      revision.version.should == 3
      revision.name.should == 'Foobar 3'
    end
    
    it "should find the previous revision with :previous" do
      revision = @user.revision(:previous)
      revision.version.should == 4
      revision.should == @user.revision(4)
    end
    
    it "should be able to get the previous revision repeatedly" do
      previous = @user.revision(:previous)
      previous.version.should == 4
      previous.revision(:previous).version.should == 3
    end
    
    it "should set the attributes for each revision" do
      u = User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'
      
      u.revision(3).name.should == 'Awesome'
      u.revision(3).username.should == 'keepers'
      
      u.revision(2).name.should == 'Foobar'
      u.revision(2).username.should == 'brandon'

      u.revision(1).name.should == 'Brandon'
      u.revision(1).username.should == 'brandon'
    end
    
    it "should not raise an error when no previous audits exist" do
      @user.audits.destroy_all
      lambda{ @user.revision(:previous) }.should_not raise_error
    end
    
    it "should mark revision's attributes as changed" do
      @user.revision(1).name_changed?.should be_true
    end
    
    it "should record new audit when saving revision" do
      lambda { @user.revision(1).save! }.should change { @user.audits.count }
    end
    
  end
  
  describe "revision_at" do
    it "should find the latest revision before the given time" do
      u = create_user
      Audit.update(u.audits.first.id, :created_at => 1.hour.ago)
      u.update_attributes :name => 'updated'
      u.revision_at(2.minutes.ago).version.should == 1
    end
    
    it "should be nil if given a time before audits" do
      create_user.revision_at(1.week.ago).should be_nil
    end

  end
  
  describe "without auditing" do
    
    it "should not save an audit when calling #save_without_auditing" do
      lambda {
        u = User.new(:name => 'Brandon')
        u.save_without_auditing.should be_true
      }.should_not change { Audit.count }
    end
    
    it "should not save an audit inside of the #without_auditing block" do
      lambda do
        User.without_auditing { User.create(:name => 'Brandon') }
      end.should_not change { Audit.count }
    end

    it "should not save an audit when callbacks are disabled" do
      begin
        User.disable_auditing_callbacks
        lambda { create_user }.should_not change { Audit.count }
      ensure
        User.enable_auditing_callbacks
      end
    end
  end

  describe "attr_protected and attr_accessible" do
    class UnprotectedUser < ActiveRecord::Base
      set_table_name :users
      acts_as_audited :protect => false
      attr_accessible :name, :username, :password
    end
    it "should not raise error when attr_accessible is set and protected is false" do
      lambda{
        UnprotectedUser.new(:name => 'NO FAIL!')
      }.should_not raise_error(RuntimeError)
    end
  
    class AccessibleUser < ActiveRecord::Base
      set_table_name :users
      attr_accessible :name, :username, :password # declare attr_accessible before calling aaa
      acts_as_audited
    end  
    it "should not raise an error when attr_accessible is declared before acts_as_audited" do
      lambda{
        AccessibleUser.new(:name => 'NO FAIL!')
      }.should_not raise_error
    end
  end

  describe "parent record tracking" do
    class ::Author < ActiveRecord::Base
      has_many :books
    end
    class ::Book < ActiveRecord::Base
      belongs_to :author
      acts_as_audited :parent => :author
    end

    before(:each) do
      @author = Author.create!( :name => 'Kenneth Kalmer' )
      @book = Book.create!( :title => 'Open Sourcery 101', :author => @author )
    end
    
    it "should give parents access to child changes" do
      @author.should respond_to(:book_audits)
      @author.should respond_to(:child_record_audits)
    end

    it "should allow detection of audited parent" do
      @author.should respond_to(:audited_parent?)
    end

    it "should track the parent in child audits" do
      @book.audits.first.auditable_parent.should == @author
      @author.book_audits.first.auditable.should == @book
      
      @author.child_record_audits.should == @author.book_audits
    end
  end
  
end
