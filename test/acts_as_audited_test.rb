require File.join(File.dirname(__FILE__), 'test_helper')

class ActsAsAuditedTest < Test::Unit::TestCase
  
  def test_acts_as_authenticated_declaration
    [:non_audited_columns, :audited_columns, :without_auditing].each do |m|
      assert User.respond_to?(m), "User class should respond to #{m}."
    end

    u = User.new
    [:audits, :save_without_auditing, :without_auditing, :audited_attributes, :changed?].each do |m|
      assert u.respond_to?(m), "User object should respond to #{m}."
    end
  end
  
  def test_audited_attributes
    assert_equal ['name', 'username', 'logins', 'activated'].sort, User.new.audited_attributes.sort
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
    assert u.changed?(:name)
    assert !u.changed?(:username)
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
    u = create_user
    audit = Audit.find(u.audits.first.id)
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
    assert_equal nil, u.revisions[0].name
    
    u.update_attribute :name, 'Foobar'
    assert_equal 2, u.revisions.size
    assert_equal 'Brandon', u.revisions[0].name
    assert_equal nil, u.revisions[1].name
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
    assert_equal 'Foobar 2', revision.name
  end
  
  def test_get_previous_revision
    u = create_versions(5)
    revision = u.revision(:previous)
    assert_equal 5, revision.version
    assert_equal u.revision(5), revision
  end
  
  def test_revision_marks_attributes_changed
    u = create_versions(2)
    assert u.revision(1).changed?(:name)
  end

  def test_save_revision_records_audit
    u = create_versions(2)
    assert_difference Audit, :count do
      assert u.revision(1).save
    end
  end
  
private

  def create_user(attrs = {})
    User.create({:name => 'Brandon', :username => 'brandon', :password => 'password'}.merge(attrs))
  end
  
  def create_versions(n = 2)
    returning User.create(:name => 'Foobar 1') do |u|
      (n - 1).times do |i|
        u.update_attribute :name, "Foobar #{i + 2}"
      end
      u.reload
    end
    
  end

end
