require File.expand_path('../boot', __FILE__)

require "rails/all"

Bundler.require :default


module RailsApp
  class Application < Rails::Application
    # Ensure the root is correct
    config.root = File.expand_path('../../', __FILE__)

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.orm             :active_record
    #   g.template_engine :erb
    #   g.test_framework  :test_unit, :fixture => true
    # end

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters << :password
  end
end
