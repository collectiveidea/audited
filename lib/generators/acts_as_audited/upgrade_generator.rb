require 'rails/generators'
require 'rails/generators/migration'
require 'active_record'
require 'rails/generators/active_record'

module Audited
  module Generators
    class UpgradeGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        if ActiveRecord::Base.timestamped_migrations
          [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
        else
          "%.3d" % next_migration_number
        end
      end

      def copy_templates
        migrations_to_be_applied do |m|
          migration_template "#{m}.rb", "db/migrate/#{m}.rb"
        end
      end

      private

      def migrations_to_be_applied
        Audited::Adapters::ActiveRecord::Audit.reset_column_information
        columns = Audited::Adapters::ActiveRecord::Audit.columns.map(&:name)

        unless columns.include?( 'comment' )
          yield :add_comment_to_audits
        end

        if columns.include?( 'changes' )
          yield :rename_changes_to_audited_changes
        end

        unless columns.include?( 'remote_address' )
          yield :add_remote_address_to_audits
        end

        unless columns.include?( 'association_id' )
          if columns.include?('auditable_parent_id')
            yield :rename_parent_to_association
          else
            unless columns.include?( 'associated_id' )
              yield :add_association_to_audits
            end
          end
        end

        if columns.include?( 'association_id' )
          yield :rename_association_to_associated
        end
      end
    end
  end
end
