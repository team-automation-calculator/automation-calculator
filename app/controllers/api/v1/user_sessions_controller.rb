module API
  module V1
    class UserSessionsController < API::V1::ApplicationController
      rate_limit to: 10, within: 1.minute

      def create
        user = User.find_by(email: params[:email])

        if user&.valid_password?(params[:password])
          sign_in(user)
        else
          hash_dummy_password unless user
          log_failed_sign_in(user)
          head :unauthorized
        end
      end

      private

      def sign_in(user)
        token = JwtTokenService.encode_token(user_id: user.id)
        response.set_header('Access-Token', token)
        logger.info("API sign-in: user=#{user.id} ip=#{request.remote_ip}")
        render json: user
      end

      # The response is the same for an unknown email and a wrong password;
      # the log keeps them apart (many unknown emails from one address is
      # credential stuffing, many wrong passwords for one user is a targeted
      # guess). The email itself is never logged.
      def log_failed_sign_in(user)
        reason = user ? "wrong_password user=#{user.id}" : 'unknown_email'
        logger.warn(
          "API 401: sign-in failed: reason=#{reason} ip=#{request.remote_ip}"
        )
      end

      # Mirror Devise's paranoid strategy: hash a password even when no
      # user matched, so an unknown email and a wrong password take about
      # the same time and cannot be told apart by response latency.
      def hash_dummy_password
        User.new.password = params[:password]
      end
    end
  end
end
