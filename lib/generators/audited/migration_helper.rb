module Audited
  module Generators
    module MigrationHelper
      def migration_parent
        Rails::VERSION::MAJOR == 4 ? 'ActiveRecord::Migration' : "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
