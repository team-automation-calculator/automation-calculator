class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  protected

  def after_sign_in_path_for(resource_or_scope)
    if resource.sign_in_count < 2
      url_for resource.automation_scenarios.first
    else
      super
    end
  end
end
