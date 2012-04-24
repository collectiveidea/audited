module RailsApp
  class Application < Rails::Application
    config.root = File.expand_path('../../', __FILE__)
  end
end
