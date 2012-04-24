require 'test_helper'

require 'generators/audited/install_generator'

class InstallGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path('../../tmp', __FILE__)
  setup :prepare_destination
  tests Audited::Generators::InstallGenerator

  test "should generate a migration" do
    run_generator %w(install)

    assert_migration "db/migrate/install_audited.rb" do |content|
      assert_match /class InstallAudited/, content
    end
  end
end
