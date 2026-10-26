module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_sign_up_path_for(resource)
      resource.automation_scenarios.order(:created_at).first
    end
  end
end
