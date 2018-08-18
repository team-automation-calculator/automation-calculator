module API
  module V1
    class UsersController < API::V1::ApplicationController
      def create
        user = User.create! registration_params

        token = JwtTokenService.encode_token(user_id: user.id)
        response.set_header('Access-Token', token)
        render json: user
      end

      protected

      def registration_params
        params.permit(:email, :password)
      end
    end
  end
end
