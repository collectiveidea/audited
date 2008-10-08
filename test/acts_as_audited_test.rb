require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class ActsAsAuditedTest < Test::Unit::TestCase
  
  def test_acts_as_authenticated_declaration_includes_instance_methods
    assert_kind_of CollectiveIdea::Acts::Audited::InstanceMethods, User.new
  end
  
  def test_acts_as_authenticated_declaration_extends_singleton_methods
    assert_kind_of CollectiveIdea::Acts::Audited::SingletonMethods, User
  end

  def test_audited_attributes
    attrs = {'name' => nil, 'username' => nil, 'logins' => 0, 'activated' => nil}
    assert_equal attrs, User.new.audited_attributes
  end
  
  def test_non_audited_columns
    ['created_at', 'updated_at', 'lock_version', 'id', 'password'].each do |column|
      assert User.non_audited_columns.include?(column), "non_audited_columns should include #{column}."
    end
  end

  def test_doesnt_save_non_audited_columns
    u = create_user
    assert !u.audits.first.changes.include?('created_at'), 'created_at should not be audited'
    assert !u.audits.first.changes.include?('updated_at'), 'updated_at should not be audited'
    assert !u.audits.first.changes.include?('password'), 'password should not be audited'
  end
  
  def test_save_audit
    u = nil
    assert_difference(Audit, :count)    { u = create_user }
    assert_difference(Audit, :count)    { assert u.update_attribute(:name, "Someone") }
    assert_no_difference(Audit, :count) { assert u.save }
    assert_difference(Audit, :count)    { assert u.destroy }
  end
  
  def test_create
    u = User.create! :name => 'Brandon'
    assert_equal 1, u.audits.count
    audit = u.audits.first
    assert_equal 'create', audit.action
    assert_equal u.audited_attributes, audit.changes
  end
  
  def test_update
    u = create_user
    u.update_attributes :name => 'Changed'
    assert_equal 2, u.audits.count
    u.reload
    audit = u.audits.first
    assert_equal 'update', audit.action
    assert_equal({'name' => 'Changed'}, audit.changes)
  end

  def test_destroy
    u = create_user
    u.destroy
    assert_equal 2, u.audits.count
    audit = u.audits.first
    assert_equal 'destroy', audit.action
    assert_nil audit.changes
  end
  
  def test_save_without_auditing
    assert_no_difference Audit, :count do
      u = User.new(:name => 'Brandon')
      assert u.save_without_auditing
    end
  end
  
  def test_without_auditing_block
    assert_no_difference Audit, :count do
      User.without_auditing { User.create(:name => 'Brandon') }
    end
  end
  
  def test_changed?
    u = create_user
    assert !u.changed?
    u.name = "Bobby"
    assert u.changed?
    assert u.name_changed?
    assert !u.username_changed?
  end
  
  def test_clears_changed_attributes_after_save
    u = User.new(:name => 'Brandon')
    assert u.changed?
    u.save
    assert !u.changed?
  end
  
  def test_type_casting
    u = create_user(:logins => 0, :activated => true)
    assert_no_difference(Audit, :count) { u.update_attribute :logins, '0' }
    assert_no_difference(Audit, :count) { u.update_attribute :logins, 0 }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, true }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, 1 }
  end
  
  def test_that_changes_is_a_hash
    audit = create_user.audits.first
    audit.reload
    assert audit.changes.is_a?(Hash)
  end
  
  def test_save_without_modifications
    u = create_user
    u.reload
    assert_nothing_raised do
      assert !u.changed?
      u.save!
    end
  end
  
  def test_revisions_should_return_array
    u = create_versions
    assert_kind_of Array, u.revisions
    u.revisions.each {|version| assert_kind_of User, version }
  end
  
  def test_latest_revision_first
    u = User.create(:name => 'Brandon')
    assert_equal 1, u.revisions.size
    assert_equal 'Brandon', u.revisions[0].name
    
    u.update_attribute :name, 'Foobar'
    assert_equal 2, u.revisions.size
    assert_equal 'Foobar', u.revisions[0].name
    assert_equal 'Brandon', u.revisions[1].name
  end
  
  def test_revisions_without_changes
    u = User.create
    assert_nothing_raised do
      assert_equal 1, u.revisions.size
    end
  end
  
  # FIXME: figure out a better way to test this
  def test_revision_at
    u = create_user
    Audit.update(u.audits.first.id, :created_at => 1.hour.ago)
    u.update_attributes :name => 'updated'
    assert_equal 1, u.revision_at(2.minutes.ago).version
  end
  
  def test_revision_at_before_record_created
    u = create_user
    assert_nil u.revision_at(1.week.ago)
  end
  
  def test_get_specific_revision
    u = create_versions(5)
    revision = u.revision(3)
    assert_kind_of User, revision
    assert_equal 3, revision.version
    assert_equal 'Foobar 3', revision.name
  end
  
  def test_get_previous_revision
    u = create_versions(5)
    revision = u.revision(:previous)
    assert_equal 4, revision.version
    assert_equal u.revision(4), revision
  end

  def test_get_previous_revision_repeatedly
    u = create_versions(5).revision(:previous)
    assert_equal 4, u.version
    assert_equal 3, u.revision(:previous).version
  end
  
  def test_revision_marks_attributes_changed
    u = create_versions(2)
    assert u.revision(1).name_changed?
  end

  def test_save_revision_records_audit
    u = create_versions(2)
    assert_difference Audit, :count do
      assert u.revision(1).save
    end
  end
  
  def test_without_previous_audits
    user = create_user
    user.audits.destroy_all
    assert_nothing_raised(NoMethodError) { user.revision(:previous) }
  end
  
  def test_without_auditing
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
  
  def test_disable_auditing_callbacks
    User.disable_auditing_callbacks
    assert_no_difference Audit, :count do
      create_user
    end
  ensure
    User.enable_auditing_callbacks
  end
  
  class InaccessibleUser < ActiveRecord::Base
    set_table_name :users
    acts_as_audited
    attr_accessible :name, :username, :password
  end
  def test_attr_accessible_breaks
    assert_raises(RuntimeError) { InaccessibleUser.new(:name => 'FAIL!') }
  end
  
  class UnprotectedUser < ActiveRecord::Base
    set_table_name :users
    acts_as_audited :protect => false
    attr_accessible :name, :username, :password
  end
  def test_attr_accessible_without_protection
    assert_nothing_raised { UnprotectedUser.new(:name => 'NO FAIL!') }
  end
  
  # declare attr_accessible before calling aaa
  class AccessibleUser < ActiveRecord::Base
    set_table_name :users
    attr_accessible :name, :username, :password
    acts_as_audited
  end
  def test_attr_accessible_without_protection
    assert_nothing_raised { AccessibleUser.new(:name => 'NO FAIL!') }
  end
  
end
