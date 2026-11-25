module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def show; end

    def update
      if @user.update permitted_profile_params
        log_account_event(:info, 'Email changed') if @user.saved_change_to_email?
        flash[:notice] = 'The User profile was updated successfully'
        redirect_to action: :show
      else
        render :show
      end
    end

    def update_password
      if @user.update_with_password permitted_password_params
        log_account_event(:info, 'Password changed')
        flash[:notice] = 'The User password was updated successfully'
        bypass_sign_in @user
        redirect_to action: :show
      else
        log_rejected_password_change
        render :show
      end
    end

    protected

    # A rejected current password on a signed-in session is worth a
    # warning (a hijacked session trying to take the account over); a
    # new password that is merely too short is not.
    def log_rejected_password_change
      wrong_current = @user.errors.include?(:current_password)
      log_account_event(
        wrong_current ? :warn : :info,
        "Password change rejected: #{@user.errors.attribute_names.join(',')}"
      )
    end

    def log_account_event(level, event)
      logger.public_send(
        level, "#{event}: user=#{@user.id} ip=#{request.remote_ip}"
      )
    end

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
