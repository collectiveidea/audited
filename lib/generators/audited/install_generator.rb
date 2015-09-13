require 'rails/generators'
require 'rails/generators/migration'
require 'active_record'
require 'rails/generators/active_record'
require 'generators/audited/migration'

module Audited
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend Audited::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      def copy_migration
        migration_template 'install.rb', 'db/migrate/install_audited.rb'
      end
    end
  end
end
