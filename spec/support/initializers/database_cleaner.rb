require 'database_cleaner'

RSpec.configure do |config|
  # Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
