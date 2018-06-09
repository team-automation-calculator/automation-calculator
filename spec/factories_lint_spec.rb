require 'rails_helper'

RSpec.context 'with all factories' do
  it 'lints all of them' do
    DatabaseCleaner.cleaning do
      FactoryGirl.lint traits: true
    end
  end
end
