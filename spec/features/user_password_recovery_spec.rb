require 'rails_helper'
RSpec.describe 'User password recovery', type: :feature do
  let!(:user) { create :user }

  def update_password
    token = user.send_reset_password_instructions
    visit edit_user_password_path(reset_password_token: token)
    fill_in 'New password', with: 'password'
    fill_in 'Confirm new password', with: 'password'
    click_button 'Change my password'
  end

  it 'displays the forgot password link' do
    visit root_url
    expect(page).to have_content('Forgot your password?')
  end

  context 'when click on forgot password link' do
    it 'sends email to user and redirect to sign in page' do
      visit new_user_password_path
      fill_in 'Email', with: user.email
      click_button 'Reset Password'
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'when update the password' do
    before { update_password }

    it 'updates the password and sign the user' do
      expect(page).to have_content('AutomationScenario')
    end
  end
end
