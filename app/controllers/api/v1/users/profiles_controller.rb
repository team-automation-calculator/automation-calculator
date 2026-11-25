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
          if current_user.saved_change_to_email?
            logger.info(
              "API email changed: user=#{current_user.id} " \
              "ip=#{request.remote_ip}"
            )
          end

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
