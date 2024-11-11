# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "active_record"
require "rails/generators/active_record"
require "generators/audited/migration"
require "generators/audited/migration_helper"

module Audited
  module Generators
    class UpgradeGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      include Audited::Generators::MigrationHelper
      extend Audited::Generators::Migration

      class_option :audited_table_name, type: :string, default: "audits", required: false
      class_option :audited_context_column_type, type: :string, default: "text", required: false

      source_root File.expand_path("../templates", __FILE__)

      def copy_templates
        migrations_to_be_applied do |template_name|
          name = "db/migrate/#{template_name}.rb"
          if options[:audited_table_name] != "audits"
            name = name.gsub("_to_audits", "_to_#{options[:audited_table_name]}")
          end
          migration_template "#{template_name}.rb", name
        end
      end

      private

      def migrations_to_be_applied
        Audited::Audit.reset_column_information
        columns = Audited::Audit.columns.map(&:name)
        indexes = Audited::Audit.connection.indexes(Audited::Audit.table_name)

        yield :add_comment_to_audits unless columns.include?("comment")

        if columns.include?("changes")
          yield :rename_changes_to_audited_changes
        end

        unless columns.include?("remote_address")
          yield :add_remote_address_to_audits
        end

        unless columns.include?("request_uuid")
          yield :add_request_uuid_to_audits
        end

        unless columns.include?("association_id")
          if columns.include?("auditable_parent_id")
            yield :rename_parent_to_association
          else
            unless columns.include?("associated_id")
              yield :add_association_to_audits
            end
          end
        end

        if columns.include?("association_id")
          yield :rename_association_to_associated
        end

        if indexes.any? { |i| i.columns == %w[associated_id associated_type] }
          yield :revert_polymorphic_indexes_order
        end

        if indexes.any? { |i| i.columns == %w[auditable_type auditable_id] }
          yield :add_version_to_auditable_index
        end

        unless columns.include?("context")
          yield :add_context_to_audits
        end
      end
    end
  end
end
