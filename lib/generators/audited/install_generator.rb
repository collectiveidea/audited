# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "active_record"
require "rails/generators/active_record"
require "generators/audited/migration"
require "generators/audited/migration_helper"

module Audited
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      include Audited::Generators::MigrationHelper
      extend Audited::Generators::Migration

      class_option :audited_changes_column_type, type: :string, default: "text", required: false
      class_option :audited_user_id_column_type, type: :string, default: "integer", required: false
      class_option :audited_table_name, type: :string, default: "audits", required: false

      source_root File.expand_path("../templates", __FILE__)

      def copy_migration
        name = "db/migrate/install_audited.rb"
        if options[:audited_table_name] != "audits"
          name = "db/migrate/create_#{options[:audited_table_name].underscore.pluralize}.rb"
        end
        migration_template "install.rb", name
      end

      def create_custom_audit
        return if options[:audited_table_name] == "audits"

        template "custom_audit.rb", "app/models/#{options[:audited_table_name].singularize.underscore}.rb"
      end
    end
  end
end
