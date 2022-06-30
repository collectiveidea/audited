# require "active_record/railtie"

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
# require "active_job/railtie"
require 'active_record/railtie'
require 'rails/test_unit/railtie'

module RailsApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.root = File.expand_path("../../", __FILE__)
    config.i18n.enforce_available_locales = true
  end
end

require "active_record/connection_adapters/sqlite3_adapter"
if ActiveRecord::ConnectionAdapters::SQLite3Adapter.respond_to?(:represent_boolean_as_integer)
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer = true
end
