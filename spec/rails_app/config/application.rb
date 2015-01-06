require 'rails/all'

module RailsApp
  class Application < Rails::Application
    config.root = File.expand_path('../../', __FILE__)
    config.i18n.enforce_available_locales = true
  end
end
