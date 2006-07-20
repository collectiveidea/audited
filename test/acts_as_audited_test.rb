require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures/user')

class ActsAsAuditedTest < Test::Unit::TestCase
  
  def test_acts_as_authenticated_declaration
    [:audit_condition, :non_audited_columns, :audited_columns, :without_auditing].each do |m|
      assert User.respond_to?(m), "User class should respond to #{m}."
    end

    u = User.new
    [:changed_attributes, :audits, :save_audit, :save_without_auditing, :without_auditing,
        :audited_attributes, :changed?, :save_audit?, :audit_condition_met?].each do |m|
      assert u.respond_to?(m), "User object should respond to #{m}."
    end
  end
  
  def test_non_audited_columns
    ['created_at', 'updated_at', 'lock_version', 'id', 'password'].each do |column|
      assert User.non_audited_columns.include?(column), "non_audited_columns should include #{column}."
    end
  end
  
  def test_save_audit_on_create
    count = Audit.count
    User.create(:name => 'Brandon', :username => 'brandon', :password => 'password')
    assert_equal count + 1, Audit.count, "An audit record should have been saved when the user was created"
  end
  
end
