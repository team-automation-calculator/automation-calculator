require 'rails_helper'
RSpec.describe 'User profile and password change', type: :feature do
  let(:user_password) { '111111' }
  let(:user) { create :user, password: user_password }

  before do
    login_as user
    visit users_profile_path
  end

  shared_examples_for 'a user profile page' do
    it 'stays on the profile page' do
      expect(page).to have_current_path(
        url_for(users_profile_path)
      )
    end
  end

  context 'when updating the profile' do
    def update_profile
      fill_in 'Email', with: new_email
      click_button 'Update Profile'
    end

    context 'with a correct email' do
      let(:new_email) { 'new@email.com' }

      specify do
        expect { update_profile }.to change { user.reload.email }.to(new_email)
      end

      it_behaves_like 'a user profile page'
    end

    context 'with an incorrect email' do
      let(:new_email) { 'wrong_email.com' }

      specify do
        expect { update_profile }
          .not_to(change { user.reload.email })
      end

      it_behaves_like 'a user profile page'
    end
  end

  context 'when updating the password' do
    def change_password
      fill_in 'user_current_password', with: current_password
      fill_in 'user_password', with: new_password
      fill_in 'user_password_confirmation', with: password_confirmation
      click_button 'Change Password'
    end

    context 'with all correct params' do
      let(:current_password) { user_password }
      let(:new_password) { '222222' }
      let(:password_confirmation) { new_password }

      specify do
        expect { change_password }
          .to change { user.reload.valid_password?(new_password) }
          .from(be_falsey)
          .to(be_truthy)
      end

      it_behaves_like 'a user profile page'
    end

    context 'with a blank current password' do
      let(:current_password) { '' }
      let(:new_password) { '222222' }
      let(:password_confirmation) { new_password }

      specify do
        expect { change_password }
          .not_to(change { user.reload.valid_password?(new_password) })
      end

      it_behaves_like 'a user profile page'
    end

    context 'with incorrect new password' do
      let(:current_password) { user_password }
      let(:new_password) { '2' }
      let(:password_confirmation) { new_password }

      specify do
        expect { change_password }
          .not_to(change { user.reload.valid_password?(new_password) })
      end

      it_behaves_like 'a user profile page'
    end

    context 'with invalid confirmation' do
      let(:current_password) { user_password }
      let(:new_password) { '222222' }
      let(:password_confirmation) { new_password + '2' }

      specify do
        expect { change_password }
          .not_to(change { user.reload.valid_password?(new_password) })
      end

      it_behaves_like 'a user profile page'
    end
  end
end
