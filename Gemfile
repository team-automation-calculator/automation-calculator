source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails'
# Dart Sass (sass-embedded) on the Sprockets pipeline; replaces sass-rails /
# sassc-rails, which wrapped the end-of-life libsass.
gem 'dartsass-sprockets', '~> 3.2'
gem 'jbuilder'
gem 'jquery-rails'
gem 'pg', '~> 1.7'
gem 'puma', '~> 8.0'
gem 'rails', '~> 7.2.0'
gem 'rake'
# JS compressor for assets:precompile; replaces uglifier.
gem 'terser', '~> 1.2'
gem 'turbolinks'

# Flexible authentication solution for Rails with Warden
gem 'devise', '~> 5.0'

# Strategy to authenticate with Google via OAuth2 in OmniAuth.
gem 'omniauth-google-oauth2', '~> 1.2'
#  GitHub strategy for OmniAuth
gem 'omniauth-github', '~> 2.0'
# omniauth 2 only accepts POST /auth/:provider; this verifies the Rails
# authenticity token on that request.
gem 'omniauth-rails_csrf_protection', '~> 2.0'
# Easiest way to add multi-environment yaml settings
gem 'config'
# brings convention over configuration to your JSON generation
gem 'active_model_serializers'
# provides Haml generators for Rails
gem 'haml', '~> 7.5'
gem 'haml-rails', '~> 3.1'
# Bootstrap 4 Ruby Gem for Rails / Sprockets and Compass
gem 'bootstrap'
# A pure ruby implementation of
# the RFC 7519 OAuth JSON Web Token (JWT) standard
gem 'jwt', '~> 3.3'

group :development, :test do
  gem 'byebug', platforms: %w[mri mingw x64_mingw]
  gem 'database_cleaner-active_record', '~> 2.2'
  gem 'letter_opener'
  # A library for setting up Ruby objects as test data
  gem 'factory_bot_rails'
  #  A library for generating fake data
  gem 'faker'
  gem 'pry'
  # A Ruby static code analyzer
  gem 'rubocop', '~> 1.92', require: false
  gem 'rubocop-capybara', '~> 3.1', require: false
  gem 'rubocop-factory_bot', '~> 2.28', require: false
  gem 'rubocop-rails', '~> 2.38', require: false
end

group :development do
  # Annotate Rails classes with schema and routes info (maintained fork of annotate)
  gem 'annotaterb', '~> 4.25'

  gem 'listen'
  gem 'web-console'

  # guard
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
end

group :test do
  gem 'capybara'
  gem 'rspec-rails', '~> 7.1'
  # The RSpec testing framework with Rails integrations
  gem 'rspec-its'

  gem 'selenium-webdriver'
  # Rspec cops for rubocop
  gem 'rubocop-rspec', '~> 3.10', require: false
  gem 'shoulda-matchers', '~> 8.0'
  # Code coverage for Ruby
  gem 'simplecov', '~> 1.3', require: false
  # Validate the JSON returned by your Rails JSON APIs
  gem 'json_matchers'
end
