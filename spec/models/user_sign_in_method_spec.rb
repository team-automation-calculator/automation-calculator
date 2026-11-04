require 'rails_helper'

RSpec.describe User do
  describe '#sign_in_method_name' do
    it 'names the GitHub provider' do
      expect(build(:user, provider: 'github').sign_in_method_name).to eq('GitHub')
    end

    it 'names the Google provider' do
      expect(build(:user, provider: 'google_oauth2').sign_in_method_name)
        .to eq('Google')
    end

    it 'describes an account without a provider as email and password' do
      expect(build(:user, provider: nil).sign_in_method_name)
        .to eq('an email address and password')
    end
  end
end
