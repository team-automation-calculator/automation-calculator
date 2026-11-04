require 'rails_helper'
RSpec.describe 'User oauth2 registration and sign in', type: :feature do
  before do
    OmniAuth.config.test_mode = true
  end

  shared_examples_for 'an oauth2 provider' do
    # omniauth 2 rejects GET /auth/:provider, so the sign-in control is a
    # button_to form that POSTs rather than a link.
    def oauth2_sign_in
      button_title = "Sign in with #{provider_link_name}"

      visit new_user_session_path
      expect(page).to have_button(button_title)
      click_button button_title
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
            token: Faker::Lorem.characters(number: 10),
            refresh_token: Faker::Lorem.characters(number: 10),
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

        it 'creates a new scenario' do
          expect { oauth2_sign_in }.to change(AutomationScenario, :count).by(1)
        end

        context 'when a user is signed in' do
          before { oauth2_sign_in }

          let(:registered_user) { User.find_by email: user.email }

          it 'signs in the user and displays a scenario' do
            expect(page).to have_text('Automation Scenario')
          end

          it 'redirects the user to the scenario page' do
            expect(page).to have_current_path(
              url_for(registered_user.automation_scenarios.last)
            )
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

          it 'signs in the user and displays a scenario' do
            expect(page).to have_text('Automation Scenario')
          end

          it 'redirects the user to the scenario page' do
            expect(page).to have_current_path(
              url_for(user.automation_scenarios.last)
            )
          end

          it 'shows the success notice' do
            expect(page).to have_text(
              "Successfully authenticated from #{provider_name} account."
            )
          end
        end
      end

      # One account per email address: Devise's uniqueness validation and the
      # unique index on users.email reject a second account for the same
      # email, whatever provider it comes from.
      context 'when the email belongs to an account on another provider' do
        let(:user) { build :user, provider: provider }
        let(:email_taken_message) do
          "An account for #{user.email} already exists and signs in with " \
            "#{other_provider_name}. Each email address can have only one " \
            "account, so sign in with #{other_provider_name} rather than " \
            "#{provider_name}."
        end

        before do
          create :user, email: user.email, provider: other_provider
          oauth2_sign_in
        end

        it 'does not create a second account for the email' do
          expect(User.where(email: user.email).count).to eq(1)
        end

        it 'returns to the sign-in page' do
          expect(page).to have_current_path(new_user_session_path)
        end

        it 'explains how the existing account signs in' do
          expect(page).to have_text(email_taken_message)
        end

        it 'does not sign the user in' do
          expect(page).to have_link('Sign in')
        end
      end

      context 'when the email belongs to an email and password account' do
        let(:user) { build :user, provider: provider }

        before do
          create :user, email: user.email, provider: nil, uid: nil
          oauth2_sign_in
        end

        it 'does not create a second account for the email' do
          expect(User.where(email: user.email).count).to eq(1)
        end

        it 'explains that the existing account uses a password' do
          expect(page).to have_text(
            "An account for #{user.email} already exists and signs in with " \
            'an email address and password.'
          )
        end
      end
    end

    context 'when it fails' do
      before do
        OmniAuth.config.mock_auth[provider] = :invalid_credentials
        oauth2_sign_in
      end

      it 'redirects to the root path' do
        expect(page).to have_current_path(root_path)
      end

      it 'does not display the protected content' do
        expect(page).to have_no_text('Protected content')
      end
    end
  end

  context 'with google provider' do
    let(:provider_link_name) { 'GoogleOauth2' }
    let(:provider) { :google_oauth2 }
    let(:provider_name) { 'Google' }
    let(:other_provider) { :github }
    let(:other_provider_name) { 'GitHub' }

    it_behaves_like 'an oauth2 provider'
  end

  context 'with github provider' do
    let(:provider_link_name) { 'GitHub' }
    let(:provider) { :github }
    let(:provider_name) { 'GitHub' }
    let(:other_provider) { :google_oauth2 }
    let(:other_provider_name) { 'Google' }

    it_behaves_like 'an oauth2 provider'
  end
end
