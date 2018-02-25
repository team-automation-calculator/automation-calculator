require 'rails_helper'
RSpec.describe 'User password recovery', type: :feature do
  let!(:user) { create :user }

  it 'displays the forgot password link' do
    visit root_url
    expect(page).to have_content('Forgot your password?')
  end

  context 'when click on forgot password link' do
    it 'sends email to user and redirect to sign in page' do
      visit new_user_password_path
      fill_in 'Email', with: user.email
      click_button 'Send me reset password instructions'
      expect(current_path).to eq '/users/sign_in'
    end

    it 'updates the password and sign the user' do
      token = user.send_reset_password_instructions
      visit edit_user_password_path(reset_password_token: token)
      fill_in 'New password', with: 'password'
      fill_in 'Confirm new password', with: 'password'
      click_button 'Change my password'
      expect(page).to have_content('Protected content')
    end
  end
end
