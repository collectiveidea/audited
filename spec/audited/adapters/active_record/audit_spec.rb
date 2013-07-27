require File.expand_path('../active_record_spec_helper', __FILE__)

describe Audited::Adapters::ActiveRecord::Audit, :adapter => :active_record do
  let(:user) { Models::ActiveRecord::User.new :name => 'Testing' }

  describe "user=" do

    it "should be able to set the user to a model object" do
      subject.user = user
      subject.user.should == user
    end

    it "should be able to set the user to nil" do
      subject.user_id = 1
      subject.user_type = 'Models::ActiveRecord::User'
      subject.username = 'joe'

      subject.user = nil

      subject.user.should be_nil
      subject.user_id.should be_nil
      subject.user_type.should be_nil
      subject.username.should be_nil
    end

    it "should be able to set the user to a string" do
      subject.user = 'test'
      subject.user.should == 'test'
    end

    it "should clear model when setting to a string" do
      subject.user = user
      subject.user = 'testing'
      subject.user_id.should be_nil
      subject.user_type.should be_nil
    end

    it "should clear the username when setting to a model" do
      subject.username = 'test'
      subject.user = user
      subject.username.should be_nil
    end

  end

  describe "revision" do

    it "should recreate attributes" do
      user = Models::ActiveRecord::User.create :name => "1"
      5.times { |i| user.update_attribute :name, (i + 2).to_s }

      user.audits.each do |audit|
        audit.revision.name.should == audit.version.to_s
      end
    end

    it "should set protected attributes" do
      u = Models::ActiveRecord::User.create(:name => 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      u.audits[2].revision.logins.should be(2)
      u.audits[1].revision.logins.should be(1)
      u.audits[0].revision.logins.should be(0)
    end

    it "should bypass attribute assignment wrappers" do
      u = Models::ActiveRecord::User.create(:name => '<Joe>')
      u.audits.first.revision.name.should == '&lt;Joe&gt;'
    end

    it "should work for deleted records" do
      user = Models::ActiveRecord::User.create :name => "1"
      user.destroy
      revision = user.audits.last.revision
      revision.name.should == user.name
      revision.should be_a_new_record
    end

  end

  it "should set the version number on create" do
    user = Models::ActiveRecord::User.create! :name => 'Set Version Number'
    user.audits.first.version.should be(1)
    user.update_attribute :name, "Set to 2"
    user.audits(true).first.version.should be(1)
    user.audits(true).last.version.should be(2)
    user.destroy
    Audited.audit_class.where(:auditable_type => 'Models::ActiveRecord::User', :auditable_id => user.id).last.version.should be(3)
  end

  describe "reconstruct_attributes" do

    it "should work with the old way of storing just the new value" do
      audits = Audited.audit_class.reconstruct_attributes([Audited.audit_class.new(:audited_changes => {'attribute' => 'value'})])
      audits['attribute'].should == 'value'
    end

  end

  describe "audited_classes" do
    class Models::ActiveRecord::CustomUser < ::ActiveRecord::Base
    end
    class Models::ActiveRecord::CustomUserSubclass < Models::ActiveRecord::CustomUser
      audited
    end

    it "should include audited classes" do
      Audited.audit_class.audited_classes.should include(Models::ActiveRecord::User)
    end

    it "should include subclasses" do
      Audited.audit_class.audited_classes.should include(Models::ActiveRecord::CustomUserSubclass)
    end
  end

  describe "new_attributes" do

    it "should return a hash of the new values" do
      Audited.audit_class.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).new_attributes.should == {'a' => 2, 'b' => 4}
    end

  end

  describe "old_attributes" do

    it "should return a hash of the old values" do
      Audited.audit_class.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).old_attributes.should == {'a' => 1, 'b' => 3}
    end

  end

  describe "as_user" do

    it "should record user objects" do
      Audited.audit_class.as_user(user) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.user.should == user
        end
      end
    end

    it "should record usernames" do
      Audited.audit_class.as_user(user.name) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.username.should == user.name
        end
      end
    end

    it "should be thread safe" do
      begin
        t1 = Thread.new do
          Audited.audit_class.as_user(user) do
            sleep 1
            Models::ActiveRecord::Company.create(:name => 'The Auditors, Inc').audits.first.user.should == user
          end
        end

        t2 = Thread.new do
          Audited.audit_class.as_user(user.name) do
            Models::ActiveRecord::Company.create(:name => 'The Competing Auditors, LLC').audits.first.username.should == user.name
            sleep 0.5
          end
        end

        t1.join
        t2.join
      rescue ActiveRecord::StatementInvalid
        STDERR.puts "Thread safety tests cannot be run with SQLite"
      end
    end

    it "should return the value from the yield block" do
      Audited.audit_class.as_user('foo') do
        42
      end.should == 42
    end

    it "should reset audited_user when the yield block raises an exception" do
      expect {
        Audited.audit_class.as_user('foo') do
          raise StandardError
        end
      }.to raise_exception
      Thread.current[:audited_user].should be_nil
    end

  end

end
