require 'rails_helper'
RSpec.describe 'User oauth2 registration and sign in', type: :feature do
  before do
    OmniAuth.config.test_mode = true
  end

  shared_examples_for :an_oauth2_provider do
    def oauth2_sign_in
      link_title = "Sign in with #{provider_link_name}"

      visit root_path
      expect(page).to have_link(link_title)
      click_link link_title
    end

    context 'when it is successful' do
      let(:oauth_data) do
        OmniAuth::AuthHash.new(
          provider: provider,
          uid: user.uid,
          info: {
            email: user.email
          },
          credentials: {
            token: Faker::Lorem.characters(10),
            refresh_token: Faker::Lorem.characters(10),
            expires_at: Time.current
          }
        )
      end

      before do
        OmniAuth.config.mock_auth[provider] = oauth_data
      end

      context 'when a user does not exist' do
        let(:user) { build :user, provider: provider }

        it 'creates a new user' do
          expect { oauth2_sign_in }.to change(User, :count).by(1)
        end

        context 'when a user is signed in' do
          before { oauth2_sign_in }

          it 'displays the user email' do
            expect(page).to have_content(user.email)
          end

          it 'signs in the user and displays a Logout link' do
            expect(page).to have_link('Sign out')
          end
        end
      end

      context 'when a user exists' do
        let(:user) { create :user, provider: provider }

        it 'does not create a new user' do
          expect { oauth2_sign_in }.not_to change(User, :count)
        end

        context 'when a user is signed in' do
          before { oauth2_sign_in }

          it 'displays the user email' do
            expect(page).to have_content(user.email)
          end

          it 'signs in the user and displays a Logout link' do
            expect(page).to have_link('Sign out')
          end
        end
      end
    end

    context 'when it fails' do
      before do
        OmniAuth.config.mock_auth[provider] = :invalid_credentials
        oauth2_sign_in
      end

      it 'redirects to the sign in form' do
        expect(page).to have_current_path(new_user_session_path)
      end

      it 'does not display the protected content' do
        expect(page).not_to have_content('Protected content')
      end
    end
  end

  context 'with google provider' do
    let(:provider_link_name) { 'GoogleOauth2' }
    let(:provider) { :google_oauth2 }

    it_behaves_like :an_oauth2_provider
  end

  context 'with github provider' do
    let(:provider_link_name) { 'GitHub' }
    let(:provider) { :github }

    it_behaves_like :an_oauth2_provider
  end
end
