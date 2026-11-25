module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      super do |user|
        logger.info("Sign-up: user=#{user.id} ip=#{request.remote_ip}") if user.persisted?
      end
    end

    protected

    def after_sign_up_path_for(resource)
      resource.automation_scenarios.order(:created_at).first
    end
  end
end
