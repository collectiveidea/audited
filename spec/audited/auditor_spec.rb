require "spec_helper"

describe Audited::Auditor do

  describe "configuration" do
    it "should include instance methods" do
      expect(Models::ActiveRecord::User.new).to be_a_kind_of( Audited::Auditor::AuditedInstanceMethods)
    end

    it "should include class methods" do
      expect(Models::ActiveRecord::User).to be_a_kind_of( Audited::Auditor::AuditedClassMethods )
    end

    ['created_at', 'updated_at', 'created_on', 'updated_on', 'lock_version', 'id', 'password'].each do |column|
      it "should not audit #{column}" do
        expect(Models::ActiveRecord::User.non_audited_columns).to include(column)
      end
    end

    context "should be configurable which conditions are audited" do
      subject { ConditionalCompany.new.send(:auditing_enabled) }

      context "when passing a method name" do
        before do
          class ConditionalCompany < ::ActiveRecord::Base
            self.table_name = 'companies'

            audited if: :public?

            def public?; end
          end
        end

        context "when conditions are true" do
          before { allow_any_instance_of(ConditionalCompany).to receive(:public?).and_return(true) }
          it     { is_expected.to be_truthy }
        end

        context "when conditions are false" do
          before { allow_any_instance_of(ConditionalCompany).to receive(:public?).and_return(false) }
          it     { is_expected.to be_falsey }
        end
      end

      context "when passing a Proc" do
        context "when conditions are true" do
          before do
            class InclusiveCompany < ::ActiveRecord::Base
              self.table_name = 'companies'
              audited if: Proc.new { true }
            end
          end

          subject { InclusiveCompany.new.send(:auditing_enabled) }

          it { is_expected.to be_truthy }
        end

        context "when conditions are false" do
          before do
            class ExclusiveCompany < ::ActiveRecord::Base
              self.table_name = 'companies'
              audited if: Proc.new { false }
            end
          end
          subject { ExclusiveCompany.new.send(:auditing_enabled) }
          it { is_expected.to be_falsey }
        end
      end
    end

    context "should be configurable which conditions aren't audited" do
      context "when using a method name" do
        before do
          class ExclusionaryCompany < ::ActiveRecord::Base
            self.table_name = 'companies'

            audited unless: :non_profit?

            def non_profit?; end
          end
        end

        subject { ExclusionaryCompany.new.send(:auditing_enabled) }

        context "when conditions are true" do
          before { allow_any_instance_of(ExclusionaryCompany).to receive(:non_profit?).and_return(true) }
          it     { is_expected.to be_falsey }
        end

        context "when conditions are false" do
          before { allow_any_instance_of(ExclusionaryCompany).to receive(:non_profit?).and_return(false) }
          it     { is_expected.to be_truthy }
        end
      end

      context "when using a proc" do
        context "when conditions are true" do
          before do
            class ExclusionaryCompany < ::ActiveRecord::Base
              self.table_name = 'companies'
              audited unless: Proc.new { |c| c.exclusive? }

              def exclusive?
                true
              end
            end
          end

          subject { ExclusionaryCompany.new.send(:auditing_enabled) }
          it      { is_expected.to be_falsey }
        end

        context "when conditions are false" do
          before do
            class InclusiveCompany < ::ActiveRecord::Base
              self.table_name = 'companies'
              audited unless: Proc.new { false }
            end
          end

          subject { InclusiveCompany.new.send(:auditing_enabled) }
          it      { is_expected.to be_truthy }
        end
      end
    end

    it "should be configurable which attributes are not audited via ignored_attributes" do
      Audited.ignored_attributes = ['delta', 'top_secret', 'created_at']
      class Secret < ::ActiveRecord::Base
        audited
      end

      expect(Secret.non_audited_columns).to include('delta', 'top_secret', 'created_at')
    end

    it "should be configurable which attributes are not audited via non_audited_columns=" do
      class Secret2 < ::ActiveRecord::Base
        audited
        self.non_audited_columns = ['delta', 'top_secret', 'created_at']
      end

      expect(Secret2.non_audited_columns).to include('delta', 'top_secret', 'created_at')
    end

    it "should not save non-audited columns" do
      previous = Models::ActiveRecord::User.non_audited_columns
      begin
        Models::ActiveRecord::User.non_audited_columns += [:favourite_device]

        expect(create_user.audits.first.audited_changes.keys.any? { |col| ['favourite_device', 'created_at', 'updated_at', 'password'].include?( col ) }).to eq(false)
      ensure
        Models::ActiveRecord::User.non_audited_columns = previous
      end
    end

    it "should not save other columns than specified in 'only' option" do
      user = Models::ActiveRecord::UserOnlyPassword.create
      user.instance_eval do
        def non_column_attr
          @non_column_attr
        end

        def non_column_attr=(val)
          attribute_will_change!("non_column_attr")
          @non_column_attr = val
        end
      end

      user.password = "password"
      user.non_column_attr = "some value"
      user.save!
      expect(user.audits.last.audited_changes.keys).to eq(%w{password})
    end

    it "should save attributes not specified in 'except' option" do
      user = Models::ActiveRecord::User.create
      user.instance_eval do
        def non_column_attr
          @non_column_attr
        end

        def non_column_attr=(val)
          attribute_will_change!("non_column_attr")
          @non_column_attr = val
        end
      end

      user.password = "password"
      user.non_column_attr = "some value"
      user.save!
      expect(user.audits.last.audited_changes.keys).to eq(%w{non_column_attr})
    end

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL' && Rails.version >= "4.2.0.0" # Postgres json and jsonb support was added in Rails 4.2
      describe "'json' and 'jsonb' audited_changes column type" do
        let(:migrations_path) { SPEC_ROOT.join("support/active_record/postgres") }

        after do
          run_migrations(:down, migrations_path)
        end

        it "should work if column type is 'json'" do
          run_migrations(:up, migrations_path, 1)
          Audited::Audit.reset_column_information
          expect(Audited::Audit.columns_hash["audited_changes"].sql_type).to eq("json")

          user = Models::ActiveRecord::User.create
          user.name = "new name"
          user.save!
          expect(user.audits.last.audited_changes).to eq({"name" => [nil, "new name"]})
        end

        it "should work if column type is 'jsonb'" do
          run_migrations(:up, migrations_path, 2)
          Audited::Audit.reset_column_information
          expect(Audited::Audit.columns_hash["audited_changes"].sql_type).to eq("jsonb")

          user = Models::ActiveRecord::User.create
          user.name = "new name"
          user.save!
          expect(user.audits.last.audited_changes).to eq({"name" => [nil, "new name"]})
        end
      end
    end
  end

  describe :new do
    it "should allow mass assignment of all unprotected attributes" do
      yesterday = 1.day.ago

      u = Models::ActiveRecord::NoAttributeProtectionUser.new(name: 'name',
                                        username: 'username',
                                        password: 'password',
                                        activated: true,
                                        suspended_at: yesterday,
                                        logins: 2)

      expect(u.name).to eq('name')
      expect(u.username).to eq('username')
      expect(u.password).to eq('password')
      expect(u.activated).to eq(true)
      expect(u.suspended_at.to_i).to eq(yesterday.to_i)
      expect(u.logins).to eq(2)
    end
  end

  describe "on create" do
    let( :user ) { create_user audit_comment: "Create" }

    it "should change the audit count" do
      expect {
        user
      }.to change( Audited::Audit, :count ).by(1)
    end

    it "should create associated audit" do
      expect(user.audits.count).to eq(1)
    end

    it "should set the action to create" do
      expect(user.audits.first.action).to eq('create')
      expect(Audited::Audit.creates.order(:id).last).to eq(user.audits.first)
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
      on_create_destroy_except_name = Models::ActiveRecord::OnCreateDestroyExceptName.create(name: 'Bart')
      expect(on_create_destroy_except_name.audits.first.audited_changes.keys.any?{|col| ['name'].include? col}).to eq(false)
    end

    it "should not save an audit if only specified on update/destroy" do
      expect {
        Models::ActiveRecord::OnUpdateDestroy.create!( name: 'Bart' )
      }.to_not change( Audited::Audit, :count )
    end
  end

  describe "on update" do
    before do
      @user = create_user( name: 'Brandon', audit_comment: 'Update' )
    end

    it "should save an audit" do
      expect {
        @user.update_attribute(:name, "Someone")
      }.to change( Audited::Audit, :count ).by(1)
      expect {
        @user.update_attribute(:name, "Someone else")
      }.to change( Audited::Audit, :count ).by(1)
    end

    it "should set the action to 'update'" do
      @user.update_attributes name: 'Changed'
      expect(@user.audits.last.action).to eq('update')
      expect(Audited::Audit.updates.order(:id).last).to eq(@user.audits.last)
      expect(@user.audits.updates.last).to eq(@user.audits.last)
    end

    it "should store the changed attributes" do
      @user.update_attributes name: 'Changed'
      expect(@user.audits.last.audited_changes).to eq({ 'name' => ['Brandon', 'Changed'] })
    end

    it "should store audit comment" do
      expect(@user.audits.last.comment).to eq('Update')
    end

    it "should not save an audit if only specified on create/destroy" do
      on_create_destroy = Models::ActiveRecord::OnCreateDestroy.create( name: 'Bart' )
      expect {
        on_create_destroy.update_attributes name: 'Changed'
      }.to_not change( Audited::Audit, :count )
    end

    it "should not save an audit if the value doesn't change after type casting" do
      @user.update_attributes! logins: 0, activated: true
      expect { @user.update_attribute :logins, '0' }.to_not change( Audited::Audit, :count )
      expect { @user.update_attribute :activated, 1 }.to_not change( Audited::Audit, :count )
      expect { @user.update_attribute :activated, '1' }.to_not change( Audited::Audit, :count )
    end

    describe "with no dirty changes" do
      it "does not create an audit if the record is not changed" do
        expect {
          @user.save!
        }.to_not change( Audited::Audit, :count )
      end

      it "creates an audit when an audit comment is present" do
        expect {
          @user.audit_comment = "Comment"
          @user.save!
        }.to change( Audited::Audit, :count )
      end
    end
  end

  describe "on destroy" do
    before do
      @user = create_user
    end

    it "should save an audit" do
      expect {
        @user.destroy
      }.to change( Audited::Audit, :count )

      expect(@user.audits.size).to eq(2)
    end

    it "should set the action to 'destroy'" do
      @user.destroy

      expect(@user.audits.last.action).to eq('destroy')
      expect(Audited::Audit.destroys.order(:id).last).to eq(@user.audits.last)
      expect(@user.audits.destroys.last).to eq(@user.audits.last)
    end

    it "should store all of the audited attributes" do
      @user.destroy

      expect(@user.audits.last.audited_changes).to eq(@user.audited_attributes)
    end

    it "should be able to reconstruct a destroyed record without history" do
      @user.audits.delete_all
      @user.destroy

      revision = @user.audits.first.revision
      expect(revision.name).to eq(@user.name)
    end

    it "should not save an audit if only specified on create/update" do
      on_create_update = Models::ActiveRecord::OnCreateUpdate.create!( name: 'Bart' )

      expect {
        on_create_update.destroy
      }.to_not change( Audited::Audit, :count )
    end

    it "should audit dependent destructions" do
      owner = Models::ActiveRecord::Owner.create!
      company = owner.companies.create!

      expect {
        owner.destroy
      }.to change( Audited::Audit, :count )

      expect(company.audits.map { |a| a.action }).to eq(['create', 'destroy'])
    end
  end

  describe "on destroy with unsaved object" do
    let(:user) { Models::ActiveRecord::User.new }

    it "should not audit on 'destroy'" do
      expect {
        user.destroy
      }.to_not raise_error

      expect( user.audits ).to be_empty
    end
  end

  describe "associated with" do
    let(:owner) { Models::ActiveRecord::Owner.create(name: 'Models::ActiveRecord::Owner') }
    let(:owned_company) { Models::ActiveRecord::OwnedCompany.create!(name: 'The auditors', owner: owner) }

    it "should record the associated object on create" do
      expect(owned_company.audits.first.associated).to eq(owner)
    end

    it "should store the associated object on update" do
      owned_company.update_attribute(:name, 'The Auditors')
      expect(owned_company.audits.last.associated).to eq(owner)
    end

    it "should store the associated object on destroy" do
      owned_company.destroy
      expect(owned_company.audits.last.associated).to eq(owner)
    end
  end

  describe "has associated audits" do
    let!(:owner) { Models::ActiveRecord::Owner.create!(name: 'Models::ActiveRecord::Owner') }
    let!(:owned_company) { Models::ActiveRecord::OwnedCompany.create!(name: 'The auditors', owner: owner) }

    it "should list the associated audits" do
      expect(owner.associated_audits.length).to eq(1)
      expect(owner.associated_audits.first.auditable).to eq(owned_company)
    end
  end

  describe "max_audits" do
    it "should respect global setting" do
      stub_global_max_audits(10) do
        expect(Models::ActiveRecord::User.audited_options[:max_audits]).to eq(10)
      end
    end

    it "should respect per model setting" do
      stub_global_max_audits(10) do
        expect(Models::ActiveRecord::MaxAuditsUser.audited_options[:max_audits]).to eq(5)
      end
    end

    it "should delete old audits when keeped amount exceeded" do
      stub_global_max_audits(2) do
        user = create_versions(2)
        user.update(name: 'John')
        expect(user.audits.pluck(:version)).to eq([2, 3])
      end
    end

    it "should not delete old audits when keeped amount not exceeded" do
      stub_global_max_audits(3) do
        user = create_versions(2)
        user.update(name: 'John')
        expect(user.audits.pluck(:version)).to eq([1, 2, 3])
      end
    end

    it "should delete old extra audits after introducing limit" do
      stub_global_max_audits(nil) do
        user = Models::ActiveRecord::User.create!(name: 'Brandon', username: 'brandon')
        user.update_attributes(name: 'Foobar')
        user.update_attributes(name: 'Awesome', username: 'keepers')
        user.update_attributes(activated: true)

        Audited.max_audits = 3
        Models::ActiveRecord::User.send(:normalize_audited_options)
        user.update_attributes(favourite_device: 'Android Phone')
        audits = user.audits

        expect(audits.count).to eq(3)
        expect(audits[0].audited_changes).to include({'name' => ['Foobar', 'Awesome'], 'username' => ['brandon', 'keepers']})
        expect(audits[1].audited_changes).to eq({'activated' => [nil, true]})
        expect(audits[2].audited_changes).to eq({'favourite_device' => [nil, 'Android Phone']})
      end
    end

    it "should add comment line for combined audit" do
      stub_global_max_audits(2) do
        user = Models::ActiveRecord::User.create!(name: 'Foobar 1')
        user.update(name: 'Foobar 2', audit_comment: 'First audit comment')
        user.update(name: 'Foobar 3', audit_comment: 'Second audit comment')
        expect(user.audits.first.comment).to match(/First audit comment.+is the result of multiple/m)
      end
    end

    def stub_global_max_audits(max_audits)
      previous_max_audits = Audited.max_audits
      previous_user_audited_options = Models::ActiveRecord::User.audited_options.dup
      begin
        Audited.max_audits = max_audits
        Models::ActiveRecord::User.send(:normalize_audited_options) # reloads audited_options
        yield
      ensure
        Audited.max_audits = previous_max_audits
        Models::ActiveRecord::User.audited_options = previous_user_audited_options
      end
    end
  end

  describe "revisions" do
    let( :user ) { create_versions }

    it "should return an Array of Users" do
      expect(user.revisions).to be_a_kind_of( Array )
      user.revisions.each { |version| expect(version).to be_a_kind_of Models::ActiveRecord::User }
    end

    it "should have one revision for a new record" do
      expect(create_user.revisions.size).to eq(1)
    end

    it "should have one revision for each audit" do
      expect(user.audits.size).to eql( user.revisions.size )
    end

    it "should set the attributes for each revision" do
      u = Models::ActiveRecord::User.create(name: 'Brandon', username: 'brandon')
      u.update_attributes name: 'Foobar'
      u.update_attributes name: 'Awesome', username: 'keepers'

      expect(u.revisions.size).to eql(3)

      expect(u.revisions[0].name).to eql('Brandon')
      expect(u.revisions[0].username).to eql('brandon')

      expect(u.revisions[1].name).to eql('Foobar')
      expect(u.revisions[1].username).to eql('brandon')

      expect(u.revisions[2].name).to eql('Awesome')
      expect(u.revisions[2].username).to eql('keepers')
    end

    it "access to only recent revisions" do
      u = Models::ActiveRecord::User.create(name: 'Brandon', username: 'brandon')
      u.update_attributes name: 'Foobar'
      u.update_attributes name: 'Awesome', username: 'keepers'

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
      user.audits.last.update_attributes audited_changes: {old_attribute: 'old value'}
      expect { user.revisions }.to_not raise_error
    end
  end

  describe "revisions" do
    let( :user ) { create_versions(5) }

    it "should maintain identity" do
      expect(user.revision(1)).to eq(user)
    end

    it "should find the given revision" do
      revision = user.revision(3)
      expect(revision).to be_a_kind_of( Models::ActiveRecord::User )
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
      u = Models::ActiveRecord::User.create(name: 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      expect(u.revision(3).logins).to eq(2)
      expect(u.revision(2).logins).to eq(1)
      expect(u.revision(1).logins).to eq(0)
    end

    it "should set attributes directly" do
      u = Models::ActiveRecord::User.create(name: '<Joe>')
      expect(u.revision(1).name).to eq('&lt;Joe&gt;')
    end

    it "should set the attributes for each revision" do
      u = Models::ActiveRecord::User.create(name: 'Brandon', username: 'brandon')
      u.update_attributes name: 'Foobar'
      u.update_attributes name: 'Awesome', username: 'keepers'

      expect(u.revision(3).name).to eq('Awesome')
      expect(u.revision(3).username).to eq('keepers')

      expect(u.revision(2).name).to eq('Foobar')
      expect(u.revision(2).username).to eq('brandon')

      expect(u.revision(1).name).to eq('Brandon')
      expect(u.revision(1).username).to eq('brandon')
    end

    it "should be able to get time for first revision" do
      suspended_at = Time.zone.now
      u = Models::ActiveRecord::User.create(suspended_at: suspended_at)
      expect(u.revision(1).suspended_at.to_s).to eq(suspended_at.to_s)
    end

    it "should not raise an error when no previous audits exist" do
      user.audits.destroy_all
      expect { user.revision(:previous) }.to_not raise_error
    end

    it "should mark revision's attributes as changed" do
      expect(user.revision(1).name_changed?).to eq(true)
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
      }.to change( Models::ActiveRecord::User, :count ).by(1)
    end

    it "should return nil for values greater than the number of revisions" do
      expect(user.revision(user.revisions.count + 1)).to be_nil
    end
  end

  describe "revision_at" do
    let( :user ) { create_user }

    it "should find the latest revision before the given time" do
      audit = user.audits.first
      audit.created_at = 1.hour.ago
      audit.save!
      user.update_attributes name: 'updated'
      expect(user.revision_at( 2.minutes.ago ).version).to eq(1)
    end

    it "should be nil if given a time before audits" do
      expect(user.revision_at( 1.week.ago )).to be_nil
    end
  end

  describe "without auditing" do
    it "should not save an audit when calling #save_without_auditing" do
      expect {
        u = Models::ActiveRecord::User.new(name: 'Brandon')
        expect(u.save_without_auditing).to eq(true)
      }.to_not change( Audited::Audit, :count )
    end

    it "should not save an audit inside of the #without_auditing block" do
      expect {
        Models::ActiveRecord::User.without_auditing { Models::ActiveRecord::User.create!( name: 'Brandon' ) }
      }.to_not change( Audited::Audit, :count )
    end

    it "should reset auditing status even it raises an exception" do
      Models::ActiveRecord::User.without_auditing { raise } rescue nil
      expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
    end

    it "should be thread safe using a #without_auditing block" do
      begin
        t1 = Thread.new do
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
          Models::ActiveRecord::User.without_auditing do
            expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
            Models::ActiveRecord::User.create!( name: 'Bart' )
            sleep 1
            expect(Models::ActiveRecord::User.auditing_enabled).to eq(false)
          end
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
        end

        t2 = Thread.new do
          sleep 0.5
          expect(Models::ActiveRecord::User.auditing_enabled).to eq(true)
          Models::ActiveRecord::User.create!( name: 'Lisa' )
        end
        t1.join
        t2.join

        expect(Models::ActiveRecord::User.find_by_name('Bart').audits.count).to eq(0)
        expect(Models::ActiveRecord::User.find_by_name('Lisa').audits.count).to eq(1)
      rescue ActiveRecord::StatementInvalid
        STDERR.puts "Thread safety tests cannot be run with SQLite"
      end
    end
  end

  describe "comment required" do

    describe "on create" do
      it "should not validate when audit_comment is not supplied when initialized" do
        expect(Models::ActiveRecord::CommentRequiredUser.new(name: 'Foo')).not_to be_valid
      end

      it "should not validate when audit_comment is not supplied trying to create" do
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: 'Foo')).not_to be_valid
      end

      it "should validate when audit_comment is supplied" do
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: 'Foo', audit_comment: 'Create')).to be_valid
      end

      it "should validate when audit_comment is not supplied, and creating is not being audited" do
        expect(Models::ActiveRecord::OnUpdateCommentRequiredUser.create(name: 'Foo')).to be_valid
        expect(Models::ActiveRecord::OnDestroyCommentRequiredUser.create(name: 'Foo')).to be_valid
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(Models::ActiveRecord::CommentRequiredUser.create(name: 'Foo')).to be_valid
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end
    end

    describe "on update" do
      let( :user ) { Models::ActiveRecord::CommentRequiredUser.create!( audit_comment: 'Create' ) }
      let( :on_create_user ) { Models::ActiveRecord::OnDestroyCommentRequiredUser.create }
      let( :on_destroy_user ) { Models::ActiveRecord::OnDestroyCommentRequiredUser.create }

      it "should not validate when audit_comment is not supplied" do
        expect(user.update_attributes(name: 'Test')).to eq(false)
      end

      it "should validate when audit_comment is not supplied, and updating is not being audited" do
        expect(on_create_user.update_attributes(name: 'Test')).to eq(true)
        expect(on_destroy_user.update_attributes(name: 'Test')).to eq(true)
      end

      it "should validate when audit_comment is supplied" do
        expect(user.update_attributes(name: 'Test', audit_comment: 'Update')).to eq(true)
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(user.update_attributes(name: 'Test')).to eq(true)
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end
    end

    describe "on destroy" do
      let( :user ) { Models::ActiveRecord::CommentRequiredUser.create!( audit_comment: 'Create' )}
      let( :on_create_user ) { Models::ActiveRecord::OnCreateCommentRequiredUser.create!( audit_comment: 'Create' ) }
      let( :on_update_user ) { Models::ActiveRecord::OnUpdateCommentRequiredUser.create }

      it "should not validate when audit_comment is not supplied" do
        expect(user.destroy).to eq(false)
      end

      it "should validate when audit_comment is supplied" do
        user.audit_comment = "Destroy"
        expect(user.destroy).to eq(user)
      end

      it "should validate when audit_comment is not supplied, and destroying is not being audited" do
        expect(on_create_user.destroy).to eq(on_create_user)
        expect(on_update_user.destroy).to eq(on_update_user)
      end

      it "should validate when audit_comment is not supplied, and auditing is disabled" do
        Models::ActiveRecord::CommentRequiredUser.disable_auditing
        expect(user.destroy).to eq(user)
        Models::ActiveRecord::CommentRequiredUser.enable_auditing
      end
    end

  end

  describe "attr_protected and attr_accessible" do

    it "should not raise error when attr_accessible is set and protected is false" do
      expect {
        Models::ActiveRecord::AccessibleAfterDeclarationUser.new(name: 'No fail!')
      }.to_not raise_error
    end

    it "should not rause an error when attr_accessible is declared before audited" do
      expect {
        Models::ActiveRecord::AccessibleAfterDeclarationUser.new(name: 'No fail!')
      }.to_not raise_error
    end
  end

  describe "audit_as" do
    let( :user ) { Models::ActiveRecord::User.create name: 'Testing' }

    it "should record user objects" do
      Models::ActiveRecord::Company.audit_as( user ) do
        company = Models::ActiveRecord::Company.create name: 'The auditors'
        company.update_attributes name: 'The Auditors'

        company.audits.each do |audit|
          expect(audit.user).to eq(user)
        end
      end
    end

    it "should record usernames" do
      Models::ActiveRecord::Company.audit_as( user.name ) do
        company = Models::ActiveRecord::Company.create name: 'The auditors'
        company.update_attributes name: 'The Auditors'

        company.audits.each do |audit|
          expect(audit.user).to eq(user.name)
        end
      end
    end
  end

  describe "after_audit" do
    let( :user ) { user = Models::ActiveRecord::UserWithAfterAudit.new }

    it "should invoke after_audit callback on create" do
      expect(user.bogus_attr).to be_nil
      expect(user.save).to eq(true)
      expect(user.bogus_attr).to eq("do something")
    end
  end

  describe "around_audit" do
    let( :user ) { user = Models::ActiveRecord::UserWithAfterAudit.new }

    it "should invoke around_audit callback on create" do
      expect(user.around_attr).to be_nil
      expect(user.save).to eq(true)
      expect(user.around_attr).to eq(user.audits.last)
    end
  end

  describe "STI auditing" do
    it "should correctly disable auditing when using STI" do
      company = Models::ActiveRecord::Company::STICompany.create name: 'The auditors'
      expect(company.type).to eq("Models::ActiveRecord::Company::STICompany")
      expect {
        Models::ActiveRecord::Company.auditing_enabled = false
        company.update_attributes name: 'STI auditors'
        Models::ActiveRecord::Company.auditing_enabled = true
      }.to_not change( Audited::Audit, :count )
    end
  end
end
