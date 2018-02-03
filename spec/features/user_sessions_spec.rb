require 'rails_helper'
RSpec.describe 'User sessions', type: :feature do
  let(:user) { create :user }

  before do
    visit root_url
    fill_in 'Email', with: user.email
    fill_in 'Password', with: password
    click_button 'Log in'
  end

  context 'with valid authentication data' do
    let(:password) { user.password }

    it 'is successful' do
      expect(page.status_code).to eq(200)
    end

    it 'sends a user to the root page' do
      expect(page).to have_current_path(root_url)
    end

    it 'displays the protected content' do
      expect(page).to have_content('Protected content')
    end
  end

  context 'with an incorrect password' do
    let(:password) { user.password + 'invalid' }

    it 'sends a user to the sign in page' do
      expect(page).to have_current_path(new_user_session_path)
    end

    it 'does not display the protected content' do
      expect(page).not_to have_content('Protected content')
    end
  end
end
