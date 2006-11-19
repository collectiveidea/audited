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
    u = User.create(:name => 'Brandon')
    assert !u.audits.first.changes.include?('created_at'), 'created_at should not be audited'
    assert !u.audits.first.changes.include?('updated_at'), 'updated_at should not be audited'
    assert !u.audits.first.changes.include?('password'), 'password should not be audited'
  end
  
  def test_save_audit
    u = User.new :name => 'Brandon', :username => 'brandon', :password => 'password'
    assert_difference(Audit, :count) { u.save }
    assert_difference(Audit, :count) { u.update_attribute(:name, "Someone") }
    assert_no_difference(Audit, :count) { u.save }
    assert_difference(Audit, :count) { u.destroy }
  end
  
  def test_save_without_auditing
    assert_no_difference Audit, :count do
      u = User.new(:name => 'Brandon')
      assert u.save_without_auditing
    end
  end
  
  def test_without_auditing
    assert_no_difference Audit, :count do
      User.without_auditing { User.create(:name => 'Brandon') }
    end
  end
  
  def test_changed?
    u = User.create(:name => 'Brandon')
    assert !u.changed?
    u.name = "Bobby"
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
    
    assert_no_difference(Audit, :count) { u.update_attribute :logins, '0' }
    assert_no_difference(Audit, :count) { u.update_attribute :logins, 0 }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, true }
    assert_no_difference(Audit, :count) { u.update_attribute :activated, 1 }
  end
  
  def test_that_changes_is_a_hash
    u = User.create(:name => 'Brandon')
    audit = Audit.find(u.audits.first.id)
    assert audit.changes.is_a?(Hash)
    assert_equal 1, audit.changes.size
  end
  
  def test_save_without_audited_modifications
    u = User.create(:name => 'Brandon')
    u = User.find(u.id) # reload
    assert_nothing_raised do
      assert !u.changed?
      u.save!
    end
  end

end
