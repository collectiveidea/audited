require "spec_helper"

describe Audited::Audit do
  let(:user) { Models::ActiveRecord::User.new name: "Testing" }

  describe "user=" do

    it "should be able to set the user to a model object" do
      subject.user = user
      expect(subject.user).to eq(user)
    end

    it "should be able to set the user to nil" do
      subject.user_id = 1
      subject.user_type = 'Models::ActiveRecord::User'
      subject.username = 'joe'

      subject.user = nil

      expect(subject.user).to be_nil
      expect(subject.user_id).to be_nil
      expect(subject.user_type).to be_nil
      expect(subject.username).to be_nil
    end

    it "should be able to set the user to a string" do
      subject.user = 'test'
      expect(subject.user).to eq('test')
    end

    it "should clear model when setting to a string" do
      subject.user = user
      subject.user = 'testing'
      expect(subject.user_id).to be_nil
      expect(subject.user_type).to be_nil
    end

    it "should clear the username when setting to a model" do
      subject.username = 'test'
      subject.user = user
      expect(subject.username).to be_nil
    end

  end

  describe "revision" do

    it "should recreate attributes" do
      user = Models::ActiveRecord::User.create name: "1"
      5.times {|i| user.update_attribute :name, (i + 2).to_s }

      user.audits.each do |audit|
        expect(audit.revision.name).to eq(audit.version.to_s)
      end
    end

    it "should set protected attributes" do
      u = Models::ActiveRecord::User.create(name: "Brandon")
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      expect(u.audits[2].revision.logins).to eq(2)
      expect(u.audits[1].revision.logins).to eq(1)
      expect(u.audits[0].revision.logins).to eq(0)
    end

    it "should bypass attribute assignment wrappers" do
      u = Models::ActiveRecord::User.create(name: "<Joe>")
      expect(u.audits.first.revision.name).to eq("&lt;Joe&gt;")
    end

    it "should work for deleted records" do
      user = Models::ActiveRecord::User.create name: "1"
      user.destroy
      revision = user.audits.last.revision
      expect(revision.name).to eq(user.name)
      expect(revision).to be_a_new_record
    end
  end

  it "should set the version number on create" do
    user = Models::ActiveRecord::User.create! name: "Set Version Number"
    expect(user.audits.first.version).to eq(1)
    user.update_attribute :name, "Set to 2"
    expect(user.audits.reload.first.version).to eq(1)
    expect(user.audits.reload.last.version).to eq(2)
    user.destroy
    expect(Audited.audit_class.where(auditable_type: "Models::ActiveRecord::User", auditable_id: user.id).last.version).to eq(3)
  end

  it "should set the request uuid on create" do
    user = Models::ActiveRecord::User.create! name: "Set Request UUID"
    expect(user.audits.reload.first.request_uuid).not_to be_blank
  end

  describe "reconstruct_attributes" do
    it "should work with the old way of storing just the new value" do
      audits = Audited.audit_class.reconstruct_attributes([Audited.audit_class.new(audited_changes: {"attribute" => "value"})])
      expect(audits["attribute"]).to eq("value")
    end
  end

  describe "audited_classes" do
    class Models::ActiveRecord::CustomUser < ::ActiveRecord::Base
    end
    class Models::ActiveRecord::CustomUserSubclass < Models::ActiveRecord::CustomUser
      audited
    end

    it "should include audited classes" do
      expect(Audited.audit_class.audited_classes).to include(Models::ActiveRecord::User)
    end

    it "should include subclasses" do
      expect(Audited.audit_class.audited_classes).to include(Models::ActiveRecord::CustomUserSubclass)
    end
  end

  describe "new_attributes" do
    it "should return a hash of the new values" do
      new_attributes = Audited.audit_class.new(audited_changes: {a: [1, 2], b: [3, 4]}).new_attributes
      expect(new_attributes).to eq({"a" => 2, "b" => 4})
    end
  end

  describe "old_attributes" do
    it "should return a hash of the old values" do
      old_attributes = Audited.audit_class.new(audited_changes: {a: [1, 2], b: [3, 4]}).old_attributes
      expect(old_attributes).to eq({"a" => 1, "b" => 3})
    end
  end

  describe "as_user" do
    it "should record user objects" do
      Audited.audit_class.as_user(user) do
        company = Models::ActiveRecord::Company.create name: "The auditors"
        company.name = "The Auditors, Inc"
        company.save

        company.audits.each do |audit|
          expect(audit.user).to eq(user)
        end
      end
    end

    it "should record usernames" do
      Audited.audit_class.as_user(user.name) do
        company = Models::ActiveRecord::Company.create name: "The auditors"
        company.name = "The Auditors, Inc"
        company.save

        company.audits.each do |audit|
          expect(audit.username).to eq(user.name)
        end
      end
    end

    it "should be thread safe" do
      begin
        expect(user.save).to eq(true)

        t1 = Thread.new do
          Audited.audit_class.as_user(user) do
            sleep 1
            expect(Models::ActiveRecord::Company.create(name: "The Auditors, Inc").audits.first.user).to eq(user)
          end
        end

        t2 = Thread.new do
          Audited.audit_class.as_user(user.name) do
            expect(Models::ActiveRecord::Company.create(name: "The Competing Auditors, LLC").audits.first.username).to eq(user.name)
            sleep 0.5
          end
        end

        t1.join
        t2.join
      end
    end if ActiveRecord::Base.connection.adapter_name != 'SQLite'

    it "should return the value from the yield block" do
      result = Audited.audit_class.as_user('foo') do
        42
      end
      expect(result).to eq(42)
    end

    it "should reset audited_user when the yield block raises an exception" do
      expect {
        Audited.audit_class.as_user('foo') do
          raise StandardError.new('expected')
        end
      }.to raise_exception('expected')
      expect(Thread.current[:audited_user]).to be_nil
    end

  end

end
