require 'spec_helper'

describe Audit do
  let(:user) { User.new :name => 'Testing' }

  describe "user=" do

    it "should be able to set the user to a model object" do
      subject.user = user
      subject.user.should == user
    end

    it "should be able to set the user to nil" do
      subject.user_id = 1
      subject.user_type = 'User'
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
      user = User.create :name => "1"
      5.times { |i| user.update_attribute :name, (i + 2).to_s }

      user.audits.each do |audit|
        audit.revision.name.should == audit.version.to_s
      end
    end

    it "should set protected attributes" do
      u = User.create(:name => 'Brandon')
      u.update_attribute :logins, 1
      u.update_attribute :logins, 2

      u.audits[2].revision.logins.should be(2)
      u.audits[1].revision.logins.should be(1)
      u.audits[0].revision.logins.should be(0)
    end

    it "should bypass attribute assignment wrappers" do
      u = User.create(:name => '<Joe>')
      u.audits.first.revision.name.should == '&lt;Joe&gt;'
    end

    it "should work for deleted records" do
      user = User.create :name => "1"
      user.destroy
      revision = user.audits.last.revision
      revision.name.should == user.name
      revision.should be_a_new_record
    end

  end

  it "should set the version number on create" do
    user = User.create! :name => 'Set Version Number'
    user.audits.first.version.should be(1)
    user.update_attribute :name, "Set to 2"
    user.audits(true).first.version.should be(1)
    user.audits(true).last.version.should be(2)
    user.destroy
    Audit.where(:auditable_type => 'User', :auditable_id => user.id).last.version.should be(3)
  end

  describe "reconstruct_attributes" do

    it "should work with the old way of storing just the new value" do
      audits = Audit.reconstruct_attributes([Audit.new(:audited_changes => {'attribute' => 'value'})])
      audits['attribute'].should == 'value'
    end

  end

  describe "audited_classes" do
    class CustomUser < ActiveRecord::Base
    end
    class CustomUserSubclass < CustomUser
      acts_as_audited
    end

    it "should include audited classes" do
      Audit.audited_classes.should include(User)
    end

    it "should include subclasses" do
      Audit.audited_classes.should include(CustomUserSubclass)
    end
  end

  describe "new_attributes" do

    it "should return a hash of the new values" do
      Audit.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).new_attributes.should == {'a' => 2, 'b' => 4}
    end

  end

  describe "old_attributes" do

    it "should return a hash of the old values" do
      Audit.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).old_attributes.should == {'a' => 1, 'b' => 3}
    end

  end

  describe "as_user" do

    it "should record user objects" do
      Audit.as_user(user) do
        company = Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.user.should == user
        end
      end
    end

    it "should record usernames" do
      Audit.as_user(user.name) do
        company = Company.create :name => 'The auditors'
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
          Audit.as_user(user) do
            sleep 1
            Company.create(:name => 'The Auditors, Inc').audits.first.user.should == user
          end
        end

        t2 = Thread.new do
          Audit.as_user(user.name) do
            Company.create(:name => 'The Competing Auditors, LLC').audits.first.username.should == user.name
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
      Audit.as_user('foo') do
        42
      end.should == 42
    end

  end

  describe "as_group" do

    it "should record tag and comment" do
      group_tag = "a group tag"
      group_comment = "a group comment"
      Audit.as_group( group_tag, group_comment ) do
        user = User.create :name => 'Test User'
        company = Company.create :name => 'Test Company'

        audits = Array.new
        audits.push(user.audits).push(company.audits).flatten.each do |audit|
          audit.tag.should == group_tag
          audit.comment.should == group_comment
        end
      end
    end

    it "should be thread safe" do
      begin
        t1 = Thread.new do
          group_tag_1 = "group tag 1"
          group_comment_1 = "group comment 1"
          Audit.as_group(group_tag_1, group_comment_1) do
            sleep 1
            company = Company.create(:name => 'The Auditors, Inc')
            company.audits.first.tag.should == group_tag_1
            company.audits.first.comment.should == group_comment_1
          end
        end

        t2 = Thread.new do
          group_tag_2 = "group tag 2"
          group_comment_2 = "group comment 2"
          Audit.as_group(group_tag_2, group_comment_2) do
            company = Company.create(:name => 'The Competing Auditors, LLC')
            company.audits.first.tag.should == group_tag_2
            company.audits.first.comment.should == group_comment_2
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
      Audit.as_group("group tag", "group comment") do
        42
      end.should == 42
    end

  end

end
