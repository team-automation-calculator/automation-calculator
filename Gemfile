source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails'
gem 'jbuilder'
gem 'jquery-rails'
gem 'pg', '~> 0.2'
gem 'puma'
gem 'rails'
gem 'rake'
gem 'sass-rails'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'
gem 'uglifier'

# Flexible authentication solution for Rails with Warden
gem 'devise'

# Strategy to authenticate with Google via OAuth2 in OmniAuth.
gem 'omniauth-google-oauth2'
#  GitHub strategy for OmniAuth
gem 'omniauth-github'
# Easiest way to add multi-environment yaml settings
gem 'config'

group :development, :test do
  gem 'byebug', platforms: %w[mri mingw x64_mingw]
  gem 'database_cleaner'
  gem 'letter_opener'
  # A library for setting up Ruby objects as test data
  gem 'factory_bot_rails'
  #  A library for generating fake data
  gem 'faker'
  gem 'pry'
  # A Ruby static code analyzer
  gem 'rubocop', require: false
end

group :development do
  # Annotate Rails classes with schema and routes info
  gem 'annotate'

  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'
end

group :test do
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  # Rspec cops for rubocop
  gem 'rubocop-rspec'
  gem 'shoulda-matchers', '~> 3.1'
  # Code coverage for Ruby
  gem 'simplecov', require: false
end
