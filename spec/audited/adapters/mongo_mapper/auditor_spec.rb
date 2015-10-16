require File.expand_path('../mongo_mapper_spec_helper', __FILE__)

describe Audited::Auditor, :adapter => :mongo_mapper do

  describe "configuration" do
    it "should include instance methods" do
      Models::MongoMapper::User.new.should be_a_kind_of(Audited::Auditor::AuditedInstanceMethods)
    end

    it "should include class methods" do
      Models::MongoMapper::User.should be_a_kind_of( Audited::Auditor::AuditedClassMethods )
    end

    ['created_at', 'updated_at', 'created_on', 'updated_on', 'lock_version', 'id', '_id', 'password'].each do |column|
      it "should not audit #{column}" do
        Models::MongoMapper::User.non_audited_columns.should include(column)
      end
    end

    it "should be configurable which attributes are not audited" do
      with_ignored_attributes(['delta', 'top_secret', 'created_at']) do
        class Secret
          include MongoMapper::Document
          audited
        end

        Secret.non_audited_columns.should include('delta', 'top_secret', 'created_at')
      end
    end

    it "should not save non-audited columns" do
      create_mongo_user.audits.first.audited_changes.keys.any? { |col| ['created_at', 'updated_at', 'password'].include?( col ) }.should be_false
    end
  end

  describe :new do
    it "should allow mass assignment of all unprotected attributes" do
      yesterday = 1.day.ago.utc

      u = Models::MongoMapper::NoAttributeProtectionUser.new(:name         => 'name',
                                                             :username     => 'username',
                                                             :password     => 'password',
                                                             :activated    => true,
                                                             :suspended_at => yesterday,
                                                             :logins       => 2)

      u.name.should eq('name')
      u.username.should eq('username')
      u.password.should eq('password')
      u.activated.should eq(true)
      u.suspended_at.to_i.should eq(yesterday.to_i)
      u.logins.should eq(2)
    end
  end

  describe "on create" do
    let( :user ) { create_mongo_user :audit_comment => "Create" }

    it "should change the audit count" do
      expect {
        user
      }.to change( Audited.audit_class, :count ).by(1)
    end

    it "should create associated audit" do
      user.audits.count.should be(1)
    end

    it "should set the action to create" do
      user.audits.first.action.should == 'create'
      Audited.audit_class.creates.sort(:id.asc).last.should == user.audits.first
      user.audits.creates.count.should == 1
      user.audits.updates.count.should == 0
      user.audits.destroys.count.should == 0
    end

    it "should store all the audited attributes" do
      user.audits.first.audited_changes.should == user.audited_attributes
    end

    it "should store comment" do
      user.audits.first.comment.should == 'Create'
    end

    it "should not audit an attribute which is excepted if specified on create or destroy" do
      on_create_destroy_except_name = Models::MongoMapper::OnCreateDestroyExceptName.create(:name => 'Bart')
      on_create_destroy_except_name.audits.first.audited_changes.keys.any?{|col| ['name'].include? col}.should be_false
    end

    it "should not save an audit if only specified on update/destroy" do
      expect {
        Models::MongoMapper::OnUpdateDestroy.create!( :name => 'Bart' )
      }.to_not change( Audited.audit_class, :count )
    end
  end

  describe "on update" do
    before do
      @user = create_mongo_user( :name => 'Brandon', :audit_comment => 'Update' )
    end

    it "should save an audit" do
      expect {
        @user.update_attribute(:name, "Someone")
      }.to change( Audited.audit_class, :count ).by(1)
      expect {
        @user.update_attribute(:name, "Someone else")
      }.to change( Audited.audit_class, :count ).by(1)
    end

    it "should set the action to 'update'" do
      @user.update_attributes :name => 'Changed'
      @user.audits.all.last.action.should == 'update'
      Audited.audit_class.updates.sort(:id.asc).last.should == @user.audits.all.last
      @user.audits.updates.last.should == @user.audits.all.last
    end

    it "should store the changed attributes" do
      now = Time.at(Time.now.to_i).utc
      @user.update_attributes :name => 'Changed', :suspended_at => now
      @user.audits.all.last.audited_changes.should == { 'name' => ['Brandon', 'Changed'], 'suspended_at' => [nil, now] }
    end

    it "should store audit comment" do
      @user.audits.all.last.comment.should == 'Update'
    end

    it "should not save an audit if only specified on create/destroy" do
      on_create_destroy = Models::MongoMapper::OnCreateDestroy.create( :name => 'Bart' )
      expect {
        on_create_destroy.update_attributes :name => 'Changed'
      }.to_not change( Audited.audit_class, :count )
    end

    it "should not save an audit if the value doesn't change after type casting" do
      @user.update_attributes! :logins => 0, :activated => true
      expect { @user.update_attribute :logins, '0' }.to_not change( Audited.audit_class, :count )
      expect { @user.update_attribute :activated, 1 }.to_not change( Audited.audit_class, :count )
      expect { @user.update_attribute :activated, '1' }.to_not change( Audited.audit_class, :count )
    end

    it "saves audits of rich objects" do
      user = Models::MongoMapper::RichObjectUser.create!(:name => 'Bart Simpson')

      expect {
        user.update_attribute(:name, 'O.J.   Simpson')
      }.to_not raise_error(BSON::InvalidDocument)

      change = user.audits.all.last.audited_changes['name']
      change.should be_all{|c| c.is_a?(String) }
      change[0].should == 'Bart Simpson'
      change[1].should == 'O.J. Simpson'
    end

    describe "with no dirty changes" do
      it "does not create an audit if the record is not changed" do
        expect {
          @user.save!
        }.to_not change( Audited.audit_class, :count )
      end

      it "creates an audit when an audit comment is present" do
        expect {
          @user.audit_comment = "Comment"
          @user.save!
        }.to change( Audited.audit_class, :count )
      end
    end
  end

  describe "on destroy" do
    before do
      @user = create_mongo_user
    end

    it "should save an audit" do
      expect {
        @user.destroy
      }.to change( Audited.audit_class, :count )

      @user.audits.size.should be(2)
    end

    it "should set the action to 'destroy'" do
      @user.destroy

      @user.audits.all.last.action.should == 'destroy'
      Audited.audit_class.destroys.sort(:id.asc).last.should == @user.audits.all.last
      @user.audits.destroys.last.should == @user.audits.all.last
    end

    it "should store all of the audited attributes" do
      @user.destroy

      @user.audits.all.last.audited_changes.should == @user.audited_attributes
    end

    it "should be able to reconstruct a destroyed record without history" do
      @user.audits.delete_all
      @user.destroy

      revision = @user.audits.first.revision
      revision.name.should == @user.name
    end

    it "should not save an audit if only specified on create/update" do
      on_create_update = Models::MongoMapper::OnCreateUpdate.create!( :name => 'Bart' )

      expect {
        on_create_update.destroy
      }.to_not change( Audited.audit_class, :count )
    end
  end

  describe "associated with" do
    let(:owner) { Models::MongoMapper::Owner.create(:name => 'Models::MongoMapper::Owner') }
    let(:owned_company) { Models::MongoMapper::OwnedCompany.create!(:name => 'The auditors', :owner => owner) }

    it "should record the associated object on create" do
      owned_company.audits.first.associated.should == owner
    end

    it "should store the associated object on update" do
      owned_company.update_attribute(:name, 'The Auditors')
      owned_company.audits.all.last.associated.should == owner
    end

    it "should store the associated object on destroy" do
      owned_company.destroy
      owned_company.audits.all.last.associated.should == owner
    end
  end

  describe "has associated audits" do
    let!(:owner) { Models::MongoMapper::Owner.create!(:name => 'Models::MongoMapper::Owner') }
    let!(:owned_company) { Models::MongoMapper::OwnedCompany.create!(:name => 'The auditors', :owner => owner) }

    it "should list the associated audits" do
      owner.associated_audits.length.should == 1
      owner.associated_audits.first.auditable.should == owned_company
    end
  end

  describe "revisions" do
    let( :user ) { create_mongo_versions }

    it "should return an Array of Users" do
      user.revisions.should be_a_kind_of( Array )
      user.revisions.each { |version| version.should be_a_kind_of Models::MongoMapper::User }
    end

    it "should have one revision for a new record" do
      create_mongo_user.revisions.size.should be(1)
    end

    it "should have one revision for each audit" do
      user.audits.size.should eql( user.revisions.size )
    end

    it "should set the attributes for each revision" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
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

    it "access to only recent revisions" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'

      u.revisions(2).size.should == 2

      u.revisions(2)[0].name.should == 'Foobar'
      u.revisions(2)[0].username.should == 'brandon'

      u.revisions(2)[1].name.should == 'Awesome'
      u.revisions(2)[1].username.should == 'keepers'
    end

    it "should be empty if no audits exist" do
      user.audits.delete_all
      user.revisions.should be_empty
    end

    it "should ignore attributes that have been deleted" do
      user.audits.all.last.update_attributes :audited_changes => {:old_attribute => 'old value'}
      expect { user.revisions }.to_not raise_error
    end
  end

  describe "revisions" do
    let( :user ) { create_mongo_versions(5) }

    it "should maintain identity" do
      user.revision(1).should == user
    end

    it "should find the given revision" do
      revision = user.revision(3)
      revision.should be_a_kind_of( Models::MongoMapper::User )
      revision.version.should be(3)
      revision.name.should == 'Foobar 3'
    end

    it "should find the previous revision with :previous" do
      revision = user.revision(:previous)
      revision.version.should be(4)
      #revision.should == user.revision(4)
      revision.attributes.should == user.revision(4).attributes
    end

    it "should be able to get the previous revision repeatedly" do
      previous = user.revision(:previous)
      previous.version.should be(4)
      previous.revision(:previous).version.should be(3)
    end

    it "should be able to set protected attributes" do
      u = Models::MongoMapper::User.create(:name => 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      u.revision(3).logins.should be(2)
      u.revision(2).logins.should be(1)
      u.revision(1).logins.should be(0)
    end

    it "should set attributes directly" do
      u = Models::MongoMapper::User.create(:name => '<Joe>')
      u.revision(1).name.should == '&lt;Joe&gt;'
    end

    it "should set the attributes for each revision" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'

      u.revision(3).name.should == 'Awesome'
      u.revision(3).username.should == 'keepers'

      u.revision(2).name.should == 'Foobar'
      u.revision(2).username.should == 'brandon'

      u.revision(1).name.should == 'Brandon'
      u.revision(1).username.should == 'brandon'
    end

    it "should be able to get time for first revision" do
      suspended_at = Time.now.utc
      u = Models::MongoMapper::User.create(:suspended_at => suspended_at)
      u.revision(1).suspended_at.to_i.should == suspended_at.to_i
    end

    it "should not raise an error when no previous audits exist" do
      user.audits.destroy_all
      expect { user.revision(:previous) }.to_not raise_error
    end

    it "should mark revision's attributes as changed" do
      user.revision(1).name_changed?.should be_true
    end

    it "should record new audit when saving revision" do
      expect {
        user.revision(1).save!
      }.to change( user.audits, :count ).by(1)
    end

    it "should re-insert destroyed records" do
      user.destroy
      expect {
        user.revision(1).save!
      }.to change( Models::MongoMapper::User, :count ).by(1)
    end
  end

  describe "revision_at" do
    let( :user ) { create_mongo_user }

    it "should find the latest revision before the given time" do
      audit = user.audits.first
      audit.created_at = 1.hour.ago
      audit.save!
      user.update_attributes :name => 'updated'
      user.revision_at( 2.minutes.ago ).version.should be(1)
    end

    it "should be nil if given a time before audits" do
      user.revision_at( 1.week.ago ).should be_nil
    end
  end

  describe "without auditing" do
    it "should not save an audit when calling #save_without_auditing" do
      expect {
        u = Models::MongoMapper::User.new(:name => 'Brandon')
        u.save_without_auditing.should be_true
      }.to_not change( Audited.audit_class, :count )
    end

    it "should not save an audit inside of the #without_auditing block" do
      expect {
        Models::MongoMapper::User.without_auditing { Models::MongoMapper::User.create!( :name => 'Brandon' ) }
      }.to_not change( Audited.audit_class, :count )
    end
  end

  describe "comment required" do

    describe "on create" do
      it "should not validate when audit_comment is not supplied" do
        Models::MongoMapper::CommentRequiredUser.new.should_not be_valid
      end

      it "should validate when audit_comment is supplied" do
        Models::MongoMapper::CommentRequiredUser.new( :audit_comment => 'Create').should be_valid
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        Models::MongoMapper::CommentRequiredUser.new.should be_valid
        Models::MongoMapper::CommentRequiredUser.enable_auditing
      end
    end

    describe "on update" do
      let( :user ) { Models::MongoMapper::CommentRequiredUser.create!( :audit_comment => 'Create' ) }

      it "should not validate when audit_comment is not supplied" do
        user.update_attributes(:name => 'Test').should be_false
      end

      it "should validate when audit_comment is supplied" do
        user.update_attributes(:name => 'Test', :audit_comment => 'Update').should be_true
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        user.update_attributes(:name => 'Test').should be_true
        Models::MongoMapper::CommentRequiredUser.enable_auditing
      end
    end

    describe "on destroy" do
      let( :user ) { Models::MongoMapper::CommentRequiredUser.create!( :audit_comment => 'Create' )}

      it "should not validate when audit_comment is not supplied" do
        user.destroy.should be_false
      end

      it "should validate when audit_comment is supplied" do
        user.audit_comment = "Destroy"
        user.destroy.should be_true
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        user.destroy.should be_true
        Models::MongoMapper::CommentRequiredUser.enable_auditing
      end
    end

  end

  describe "attr_protected and attr_accessible" do

    it "should not raise error when attr_accessible is set and protected is false" do
      expect {
        Models::MongoMapper::AccessibleAfterDeclarationUser.new(:name => 'No fail!')
      }.to_not raise_error
    end

    it "should not rause an error when attr_accessible is declared before audited" do
      expect {
        Models::MongoMapper::AccessibleAfterDeclarationUser.new(:name => 'No fail!')
      }.to_not raise_error
    end
  end

  describe "audit_as" do
    let( :user ) { Models::MongoMapper::User.create :name => 'Testing' }

    it "should record user objects" do
      Models::MongoMapper::Company.audit_as( user ) do
        company = Models::MongoMapper::Company.create :name => 'The auditors'
        company.update_attributes :name => 'The Auditors'

        company.audits.each do |audit|
          audit.user.should == user
        end
      end
    end

    it "should record usernames" do
      Models::MongoMapper::Company.audit_as( user.name ) do
        company = Models::MongoMapper::Company.create :name => 'The auditors'
        company.update_attributes :name => 'The Auditors'

        company.audits.each do |audit|
          audit.user.should == user.name
        end
      end
    end
  end

  describe "after_audit" do
    let( :user ) { user = Models::MongoMapper::UserWithAfterAudit.new }

    it "should invoke after_audit callback on create" do
      user.bogus_attr.should == nil
      user.save.should == true
      user.bogus_attr.should == "do something"
    end
  end

end
