module RailsApp
  class Application < Rails::Application
    config.root = File.expand_path('../../', __FILE__)

    # Silence deprecation warnings
    config.i18n.enforce_available_locales = false
  end
end
