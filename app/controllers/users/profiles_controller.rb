module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def show; end

    def update
      if @user.update permitted_profile_params
        flash[:notice] = 'The User profile was updated successfully'
        redirect_to action: :show
      else
        render :show
      end
    end

    def update_password
      if @user.update_with_password permitted_password_params
        flash[:notice] = 'The User password was updated successfully'
        bypass_sign_in @user
        redirect_to action: :show
      else
        render :show
      end
    end

    protected

    def set_user
      @user = current_user
    end

    def permitted_profile_params
      params.require(:user).permit(
        :email
      )
    end

    def permitted_password_params
      params.require(:user).permit(
        :current_password, :password, :password_confirmation
      )
    end
  end
end
