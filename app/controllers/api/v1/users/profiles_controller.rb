module API
  module V1
    module Users
      class ProfilesController < API::V1::ApplicationController
        before_action :authenticate_user!
        before_action :verify_current_password!, only: :update

        def show
          render json: current_user
        end

        def update
          current_user.update! permitted_params

          render json: current_user
        end

        protected

        def permitted_params
          params.permit(:email)
        end
      end
    end
  end
end
