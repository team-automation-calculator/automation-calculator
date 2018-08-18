module API
  module V1
    class UserSessionsController < API::V1::ApplicationController
      def create
        user = User.find_by!(email: params[:email])

        if user.valid_password?(params[:password])
          token = JwtTokenService.encode_token(user_id: user.id)
          response.set_header('Access-Token', token)
          render json: user
        else
          head :unauthorized
        end
      end
    end
  end
end
