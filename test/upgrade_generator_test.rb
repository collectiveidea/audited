require 'test_helper'

require 'generators/acts_as_audited/upgrade_generator'

class UpgradeGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../../tmp', __FILE__)
  setup :prepare_destination
  tests ActsAsAudited::Generators::UpgradeGenerator

  test "should add 'comment' to audits table" do
    load_schema 1

    run_generator %w(upgrade)

    assert_migration "db/migrate/add_comment_to_audits.rb" do |content|
      assert_match /add_column :audits, :comment, :string/, content
    end

    assert_migration "db/migrate/rename_changes_to_audited_changes.rb"
  end

  test "should rename 'changes' to 'audited_changes'" do
    load_schema 2

    run_generator %w(upgrade)

    assert_no_migration "db/migrate/add_comment_to_audits.rb"

    assert_migration "db/migrate/rename_changes_to_audited_changes.rb" do |content|
      assert_match /rename_column :audits, :changes, :audited_changes/, content
    end
  end

  test "should add a 'remote_address' to audits table" do
    load_schema 3

    run_generator %w(upgrade)

    assert_migration "db/migrate/add_remote_address_to_audits.rb" do |content|
      assert_match /add_column :audits, :remote_address, :string/, content
    end
  end

  test "should add 'association_id' and 'association_type' to audits table" do
    load_schema 4

    run_generator %w(upgrade)

    assert_migration "db/migrate/add_association_to_audits.rb" do |content|
      assert_match /add_column :audits, :association_id, :integer/, content
      assert_match /add_column :audits, :association_type, :string/, content
    end
  end

  test "should rename 'association_id' to 'associated_id' and 'association_type' to 'associated_type'" do
    load_schema 5

    run_generator %w(upgrade)

    assert_migration "db/migrate/rename_association_to_associated.rb" do |content|
      assert_match /rename_column :audits, :association_id, :associated_id/, content
      assert_match /rename_column :audits, :association_type, :associated_type/, content
    end
  end
end
