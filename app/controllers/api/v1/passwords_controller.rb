module API
  module V1
    class PasswordsController < API::V1::ApplicationController
      def update
        user = User.find_by! email: params[:email]
        user.send_reset_password_instructions

        head :ok
      end
    end
  end
end
