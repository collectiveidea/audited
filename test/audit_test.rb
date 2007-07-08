require File.join(File.dirname(__FILE__), 'test_helper')

class AuditedTest < Test::Unit::TestCase

  def test_set_user_to_model
    @user = User.new :name => "testing"
    @audit = Audit.new :user => @user
    assert_equal @user, @audit.user
  end

  def test_set_user_to_nil
    test_set_user_to_model
    @audit.user = nil
    assert_nil @audit.user
    assert_nil @audit[:user_id]
    assert_nil @audit[:user_type]
    assert_nil @audit[:username]
  end
  
  def test_set_user_to_string
    @audit = Audit.new :user => "testing"
    assert_equal "testing", @audit.user
  end
  
  def test_set_to_string_then_model
    @user = User.new :name => "testing"
    @audit = Audit.new :user => "testing"
    @audit.user = @user
    assert_equal @user, @audit.user
    assert_nil @audit.username
  end
  
  def test_revision
    user = User.create :name => "1"
    5.times {|i| user.update_attribute :name, (i + 2).to_s  }
    user.audits.each do |audit|
      assert_equal audit.version.to_s, audit.revision.name
    end
  end

  def test_revision_for_deleted_model
    user = User.create :name => "1"
    user.destroy
    revision = user.audits.last.revision
    assert_equal user.name, revision.name
    assert revision.new_record?
  end

end