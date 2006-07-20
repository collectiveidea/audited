require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures/user')

class ActsAsAuditedTest < Test::Unit::TestCase
  
  def test_acts_as_authenticated_declaration
    [:audit_condition, :non_audited_columns, :audited_columns, :without_auditing].each do |m|
      assert User.respond_to?(m), "User class should respond to #{m}."
    end

    u = User.new
    [:changed_attributes, :audits, :save_without_auditing, :without_auditing,
        :audited_attributes, :changed?, :save_audit?, :audit_condition_met?].each do |m|
      assert u.respond_to?(m), "User object should respond to #{m}."
    end
  end
  
  def test_non_audited_columns
    ['created_at', 'updated_at', 'lock_version', 'id', 'password'].each do |column|
      assert User.non_audited_columns.include?(column), "non_audited_columns should include #{column}."
    end
  end
  
  def test_calls_clear_changed_attributes_after_save
    u = User.new(:name => 'Brandon')
    assert_equal 1, u.changed_attributes.size
    u.save
    assert_equal 0, u.changed_attributes.size
  end
  
  def test_save_audit_on_create
    count = Audit.count
    User.create(:name => 'Brandon', :username => 'brandon', :password => 'password')
    assert_equal count + 1, Audit.count, "An audit record should have been saved when the user was created"
  end
  
  def test_save_without_auditing
    u = User.new(:name => 'Brandon')
    assert u.save_without_auditing
    assert_equal 0, u.audits.count, "should not have saved and audit when calling save_without_audits"
  end
  
  def test_changed?
    u = User.new(:name => 'Brandon')
    assert u.changed?
    assert u.changed?(:name)
    assert !u.changed?(:username)
  end
  
  def test_audited_attributes
    assert_equal ['name', 'username'], User.new.audited_attributes
  end
  
  def test_doesnt_save_non_audited_columns
    u = User.create(:name => 'Brandon')
    assert !u.audits.first.changes.include?('created_at'), 'created_at should not be audited'
    assert !u.audits.first.changes.include?('updated_at'), 'updated_at should not be audited'
    assert !u.audits.first.changes.include?('password'), 'password should not be audited'
  end
  
end
