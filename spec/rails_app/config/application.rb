require 'rails/all'

module RailsApp
  class Application < Rails::Application
    config.root = File.expand_path('../../', __FILE__)
    config.i18n.enforce_available_locales = true
  end
end

require 'active_record/connection_adapters/sqlite3_adapter'
if ActiveRecord::ConnectionAdapters::SQLite3Adapter.respond_to?(:represent_boolean_as_integer)
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer = true
end
