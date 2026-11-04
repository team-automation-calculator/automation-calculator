module API
  module V1
    class PasswordsController < API::V1::ApplicationController
      rate_limit to: 10, within: 1.minute

      def update
        # Always respond :ok so the response does not reveal whether the
        # email belongs to a registered user (account-enumeration oracle).
        user = User.find_by(email: params[:email])
        user&.send_reset_password_instructions

        head :ok
      end
    end
  end
end
