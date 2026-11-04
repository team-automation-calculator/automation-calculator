module API
  module V1
    module Users
      class PasswordsController < API::V1::ApplicationController
        before_action :authenticate_user!
        before_action :verify_current_password!

        def update
          current_user.update! password: params[:password]

          render json: current_user
        end
      end
    end
  end
end
