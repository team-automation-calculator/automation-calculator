source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'pg', '~> 0.18'
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.4'
gem 'rake', '12.3.0'
gem 'sass-rails', '~> 5.0'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# Flexible authentication solution for Rails with Warden
gem 'devise'

group :development, :test do
  gem 'byebug', platforms: %w[mri mingw x64_mingw]
  gem 'capybara', '~> 2.13'
  gem 'rspec-rails', '~> 3.7'
  gem 'selenium-webdriver'
  # A library for setting up Ruby objects as test data
  gem 'factory_bot_rails'

  # A Ruby static code analyzer
  gem 'rubocop', require: false
  # Rspec cops for rubocop
  gem 'rubocop-rspec'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'

  # Annotate Rails classes with schema and routes info
  gem 'annotate'
end
