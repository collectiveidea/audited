require File.expand_path('../mongo_mapper_spec_helper', __FILE__)

describe Audited::Auditor, :adapter => :mongo_mapper do

  describe "configuration" do
    it "should include instance methods" do
      expect(Models::MongoMapper::User.new).to be_a_kind_of(Audited::Auditor::AuditedInstanceMethods)
    end

    it "should include class methods" do
      expect(Models::MongoMapper::User).to be_a_kind_of( Audited::Auditor::AuditedClassMethods )
    end

    ['created_at', 'updated_at', 'created_on', 'updated_on', 'lock_version', 'id', '_id', 'password'].each do |column|
      it "should not audit #{column}" do
        expect(Models::MongoMapper::User.non_audited_columns).to include(column)
      end
    end

    it "should be configurable which attributes are not audited" do
      Audited.ignored_attributes = ['delta', 'top_secret', 'created_at']
      class Secret
        include MongoMapper::Document
        audited
      end

      expect(Secret.non_audited_columns).to include('delta', 'top_secret', 'created_at')
    end

    it "should not save non-audited columns" do
      expect(create_mongo_user.audits.first.audited_changes.keys.any? { |col| ['created_at', 'updated_at', 'password'].include?( col ) }).to eq(false)
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

      expect(u.name).to eq('name')
      expect(u.username).to eq('username')
      expect(u.password).to eq('password')
      expect(u.activated).to eq(true)
      expect(u.suspended_at.to_i).to eq(yesterday.to_i)
      expect(u.logins).to eq(2)
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
      expect(user.audits.count).to eq(1)
    end

    it "should set the action to create" do
      expect(user.audits.first.action).to eq('create')
      expect(Audited.audit_class.creates.sort(:id.asc).last).to eq(user.audits.first)
      expect(user.audits.creates.count).to eq(1)
      expect(user.audits.updates.count).to eq(0)
      expect(user.audits.destroys.count).to eq(0)
    end

    it "should store all the audited attributes" do
      expect(user.audits.first.audited_changes).to eq(user.audited_attributes)
    end

    it "should store comment" do
      expect(user.audits.first.comment).to eq('Create')
    end

    it "should not audit an attribute which is excepted if specified on create or destroy" do
      on_create_destroy_except_name = Models::MongoMapper::OnCreateDestroyExceptName.create(:name => 'Bart')
      expect(on_create_destroy_except_name.audits.first.audited_changes.keys.any?{|col| ['name'].include? col}).to eq(false)
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
      expect(@user.audits.all.last.action).to eq('update')
      expect(Audited.audit_class.updates.sort(:id.asc).last).to eq(@user.audits.all.last)
      expect(@user.audits.updates.last).to eq(@user.audits.all.last)
    end

    it "should store the changed attributes" do
      now = Time.at(Time.now.to_i).utc
      @user.update_attributes :name => 'Changed', :suspended_at => now
      expect(@user.audits.all.last.audited_changes).to eq({ 'name' => ['Brandon', 'Changed'], 'suspended_at' => [nil, now] })
    end

    it "should store audit comment" do
      expect(@user.audits.all.last.comment).to eq('Update')
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
      }.to_not raise_error

      change = user.audits.all.last.audited_changes['name']
      expect(change).to be_all{|c| c.is_a?(String) }
      expect(change[0]).to eq('Bart Simpson')
      expect(change[1]).to eq('O.J. Simpson')
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

      expect(@user.audits.size).to eq(2)
    end

    it "should set the action to 'destroy'" do
      @user.destroy

      expect(@user.audits.all.last.action).to eq('destroy')
      expect(Audited.audit_class.destroys.sort(:id.asc).last).to eq(@user.audits.all.last)
      expect(@user.audits.destroys.last).to eq(@user.audits.all.last)
    end

    it "should store all of the audited attributes" do
      @user.destroy

      expect(@user.audits.all.last.audited_changes).to eq(@user.audited_attributes)
    end

    it "should be able to reconstruct a destroyed record without history" do
      @user.audits.delete_all
      @user.destroy

      revision = @user.audits.first.revision
      expect(revision.name).to eq(@user.name)
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
      expect(owned_company.audits.first.associated).to eq(owner)
    end

    it "should store the associated object on update" do
      owned_company.update_attribute(:name, 'The Auditors')
      expect(owned_company.audits.all.last.associated).to eq(owner)
    end

    it "should store the associated object on destroy" do
      owned_company.destroy
      expect(owned_company.audits.all.last.associated).to eq(owner)
    end
  end

  describe "has associated audits" do
    let!(:owner) { Models::MongoMapper::Owner.create!(:name => 'Models::MongoMapper::Owner') }
    let!(:owned_company) { Models::MongoMapper::OwnedCompany.create!(:name => 'The auditors', :owner => owner) }

    it "should list the associated audits" do
      expect(owner.associated_audits.length).to eq(1)
      expect(owner.associated_audits.first.auditable).to eq(owned_company)
    end
  end

  describe "revisions" do
    let( :user ) { create_mongo_versions }

    it "should return an Array of Users" do
      expect(user.revisions).to be_a_kind_of( Array )
      user.revisions.each { |version| expect(version).to be_a_kind_of(Models::MongoMapper::User) }
    end

    it "should have one revision for a new record" do
      expect(create_mongo_user.revisions.size).to eq(1)
    end

    it "should have one revision for each audit" do
      expect(user.audits.size).to eql( user.revisions.size )
    end

    it "should set the attributes for each revision" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'

      expect(u.revisions.size).to eq(3)

      expect(u.revisions[0].name).to eq('Brandon')
      expect(u.revisions[0].username).to eq('brandon')

      expect(u.revisions[1].name).to eq('Foobar')
      expect(u.revisions[1].username).to eq('brandon')

      expect(u.revisions[2].name).to eq('Awesome')
      expect(u.revisions[2].username).to eq('keepers')
    end

    it "access to only recent revisions" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'

      expect(u.revisions(2).size).to eq(2)

      expect(u.revisions(2)[0].name).to eq('Foobar')
      expect(u.revisions(2)[0].username).to eq('brandon')

      expect(u.revisions(2)[1].name).to eq('Awesome')
      expect(u.revisions(2)[1].username).to eq('keepers')
    end

    it "should be empty if no audits exist" do
      user.audits.delete_all
      expect(user.revisions).to be_empty
    end

    it "should ignore attributes that have been deleted" do
      user.audits.all.last.update_attributes :audited_changes => {:old_attribute => 'old value'}
      expect { user.revisions }.to_not raise_error
    end
  end

  describe "revisions" do
    let( :user ) { create_mongo_versions(5) }

    it "should maintain identity" do
      expect(user.revision(1)).to eq(user)
    end

    it "should find the given revision" do
      revision = user.revision(3)
      expect(revision).to be_a_kind_of( Models::MongoMapper::User )
      expect(revision.version).to eq(3)
      expect(revision.name).to eq('Foobar 3')
    end

    it "should find the previous revision with :previous" do
      revision = user.revision(:previous)
      expect(revision.version).to eq(4)
      #expect(revision).to eq(user.revision(4))
      expect(revision.attributes).to eq(user.revision(4).attributes)
    end

    it "should be able to get the previous revision repeatedly" do
      previous = user.revision(:previous)
      expect(previous.version).to eq(4)
      expect(previous.revision(:previous).version).to eq(3)
    end

    it "should be able to set protected attributes" do
      u = Models::MongoMapper::User.create(:name => 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      expect(u.revision(3).logins).to eq(2)
      expect(u.revision(2).logins).to eq(1)
      expect(u.revision(1).logins).to eq(0)
    end

    it "should set attributes directly" do
      u = Models::MongoMapper::User.create(:name => '<Joe>')
      expect(u.revision(1).name).to eq('&lt;Joe&gt;')
    end

    it "should set the attributes for each revision" do
      u = Models::MongoMapper::User.create(:name => 'Brandon', :username => 'brandon')
      u.update_attributes :name => 'Foobar'
      u.update_attributes :name => 'Awesome', :username => 'keepers'

      expect(u.revision(3).name).to eq('Awesome')
      expect(u.revision(3).username).to eq('keepers')

      expect(u.revision(2).name).to eq('Foobar')
      expect(u.revision(2).username).to eq('brandon')

      expect(u.revision(1).name).to eq('Brandon')
      expect(u.revision(1).username).to eq('brandon')
    end

    it "should be able to get time for first revision" do
      suspended_at = Time.now.utc
      u = Models::MongoMapper::User.create(:suspended_at => suspended_at)
      expect(u.revision(1).suspended_at.to_i).to eq(suspended_at.to_i)
    end

    it "should not raise an error when no previous audits exist" do
      user.audits.destroy_all
      expect { user.revision(:previous) }.to_not raise_error
    end

    it "should mark revision's attributes as changed" do
      expect(user.revision(1).name_changed?).to eq(true)
    end

    it "should record new audit when saving revision" do
      user.destroy
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
      expect(user.revision_at( 2.minutes.ago ).version).to eq(1)
    end

    it "should be nil if given a time before audits" do
      expect(user.revision_at( 1.week.ago )).to be_nil
    end
  end

  describe "without auditing" do
    it "should not save an audit when calling #save_without_auditing" do
      expect {
        u = Models::MongoMapper::User.new(:name => 'Brandon')
        expect(u.save_without_auditing).to eq(true)
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
        expect(Models::MongoMapper::CommentRequiredUser.new).not_to be_valid
      end

      it "should validate when audit_comment is supplied" do
        expect(Models::MongoMapper::CommentRequiredUser.new( :audit_comment => 'Create')).to be_valid
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        expect(Models::MongoMapper::CommentRequiredUser.new).to be_valid
        Models::MongoMapper::CommentRequiredUser.enable_auditing
      end
    end

    describe "on update" do
      let( :user ) { Models::MongoMapper::CommentRequiredUser.create!( :audit_comment => 'Create' ) }

      it "should not validate when audit_comment is not supplied" do
        expect(user.update_attributes(:name => 'Test')).to eq(false)
      end

      it "should validate when audit_comment is supplied" do
        expect(user.update_attributes(:name => 'Test', :audit_comment => 'Update')).to eq(true)
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        expect(user.update_attributes(:name => 'Test')).to eq(true)
        Models::MongoMapper::CommentRequiredUser.enable_auditing
      end
    end

    describe "on destroy" do
      let( :user ) { Models::MongoMapper::CommentRequiredUser.create!( :audit_comment => 'Create' )}

      it "should not validate when audit_comment is not supplied" do
        expect(user.destroy).to eq(false)
      end

      it "should validate when audit_comment is supplied" do
        user.audit_comment = "Destroy"
        user.destroy
        expect(user).to be_destroyed
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::MongoMapper::CommentRequiredUser.disable_auditing
        user.destroy
        expect(user).to be_destroyed
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
          expect(audit.user).to eq(user)
        end
      end
    end

    it "should record usernames" do
      Models::MongoMapper::Company.audit_as( user.name ) do
        company = Models::MongoMapper::Company.create :name => 'The auditors'
        company.update_attributes :name => 'The Auditors'

        company.audits.each do |audit|
          expect(audit.user).to eq(user.name)
        end
      end
    end
  end

  describe "after_audit" do
    let( :user ) { user = Models::MongoMapper::UserWithAfterAudit.new }

    it "should invoke after_audit callback on create" do
      expect(user.bogus_attr).to be_nil
      expect(user.save).to eq(true)
      expect(user.bogus_attr).to eq("do something")
    end
  end

end
