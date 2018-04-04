require 'test_helper'

require 'generators/audited/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../../tmp', __FILE__)
  setup :prepare_destination
  tests Audited::Generators::InstallGenerator

  test "generate migration with correct AR migration parent" do
    run_generator

    assert_migration "db/migrate/install_audited.rb" do |content|
      parent = Rails::VERSION::MAJOR == 4 ? 'ActiveRecord::Migration' : "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      assert_includes(content, "class InstallAudited < #{parent}\n")
    end
  end
end
