require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  # The main class of the Rails application
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Autoload lib/ (lib/allowed_hosts.rb is also required explicitly by
    # config/initializers/host_authorization.rb). assets and tasks hold no
    # Ruby constants.
    config.autoload_lib(ignore: %w[assets tasks])

    # Settings in config/environments/* take precedence
    # over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
