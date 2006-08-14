require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures/user')

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
    u = User.create(:name => 'Brandon')
    assert !u.audits.first.changes.include?('created_at'), 'created_at should not be audited'
    assert !u.audits.first.changes.include?('updated_at'), 'updated_at should not be audited'
    assert !u.audits.first.changes.include?('password'), 'password should not be audited'
  end
  
  def test_save_audit
    count = Audit.count
    u = User.create(:name => 'Brandon', :username => 'brandon', :password => 'password')
    assert_equal count + 1, Audit.count, "An audit record should have been saved when the user was created."
    u.update_attribute(:name, "Someone")
    assert_equal count + 2, Audit.count, "An audit record should have been saved when the user was updated."
    u.save
    assert_equal count + 2, Audit.count, "An audit record shouldn't have been saved if the user was not modified."
    u.destroy
    assert_equal count + 3, Audit.count, "An audit record should have been saved when the user was destroyed."
  end
  
  def test_save_without_auditing
    count = Audit.count
    u = User.new(:name => 'Brandon')
    assert u.save_without_auditing
    assert_equal count, Audit.count, "should not have saved and audit when calling save_without_audits"
  end
  
  def test_without_auditing
    count = Audit.count
    User.without_auditing do
      User.create(:name => 'Brandon')
    end
    assert_equal count, Audit.count, "should not have saved and audit when calling save_without_audits"
  end
  
  def test_changed?
    u = User.new(:name => 'Brandon')
    assert u.changed?
    assert u.changed?(:name)
    assert !u.changed?(:username)
  end
  
  def test_calls_clear_changed_attributes_after_save
    u = User.new(:name => 'Brandon')
    assert u.changed?
    u.save
    assert !u.changed?
  end
  
  def test_type_casting
    u = User.create(:name => 'Brandon', :logins => 0, :activated => true)
    audits = Audit.count
    
    u.update_attribute :logins, '0'
    assert_equal audits, Audit.count, "Setting to same value should not create a new audit"

    u.update_attribute :logins, 0
    assert_equal audits, Audit.count, "Setting to same value should not create a new audit"
    
    u.update_attribute :activated, true
    assert_equal audits, Audit.count, "Setting to same value should not create a new audit"

    u.update_attribute :activated, 1
    assert_equal audits, Audit.count, "Setting to same value should not create a new audit"
  end
  
  def test_that_changes_is_a_hash
    u = User.create(:name => 'Brandon')
    audit = Audit.find(u.audits.first.id)
    assert audit.changes.is_a?(Hash)
    assert_equal 1, audit.changes.size
  end

end
