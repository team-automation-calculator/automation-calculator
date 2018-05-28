require 'rails_helper'
RSpec.describe 'User registrations', type: :feature do
  let(:user) { build :user }

  def sign_up
    visit new_user_registration_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    fill_in 'Password confirmation', with: user.password
    click_button 'Sign up'
  end

  it 'creates a user' do
    expect { sign_up }.to change(User, :count).by(1)
  end

  it 'creates a scenario' do
    expect { sign_up }.to change(AutomationScenario, :count).by(1)
  end

  context 'when a user signs up successfully' do
    before { sign_up }
    let(:registered_user) { User.find_by email: user.email }

    it 'sends a user to the first scenario' do
      expect(page).to have_current_path(
        url_for(registered_user.automation_scenarios.last)
      )
    end

    it 'displays the protected content' do
      expect(page).to have_content('Automation Scenario')
    end

    context 'when the user signs in' do
      before do
        logout :user
        login_as user
      end

      it 'sets the current user to the registered user' do
        expect(page).to have_content('Automation Scenario')
      end
    end
  end
end
