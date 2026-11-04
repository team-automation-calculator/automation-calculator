module API
  module V1
    class UserSessionsController < API::V1::ApplicationController
      rate_limit to: 10, within: 1.minute

      def create
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          token = JwtTokenService.encode_token(user_id: user.id)
          response.set_header('Access-Token', token)
          render json: user
        else
          hash_dummy_password unless user
          head :unauthorized
        end
      end

      private

      # Mirror Devise's paranoid strategy: hash a password even when no
      # user matched, so an unknown email and a wrong password take about
      # the same time and cannot be told apart by response latency.
      def hash_dummy_password
        User.new.password = params[:password]
      end
    end
  end
end
