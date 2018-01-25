source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails'
gem 'jbuilder'
gem 'pg'
gem 'puma'
gem 'rails'
gem 'rake'
gem 'sass-rails'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks'
gem 'uglifier'

# Flexible authentication solution for Rails with Warden
gem 'devise'

group :development, :test do
  gem 'byebug', platforms: %w[mri mingw x64_mingw]
  gem 'capybara'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  # A library for setting up Ruby objects as test data
  gem 'factory_bot_rails'
  #  A library for generating fake data
  gem 'faker'

  # A Ruby static code analyzer
  gem 'rubocop', require: false
  # Rspec cops for rubocop
  gem 'rubocop-rspec'
end

group :development do
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'web-console'

  # Annotate Rails classes with schema and routes info
  gem 'annotate'
end
