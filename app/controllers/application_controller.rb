class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout :layout_selector

  def default_url_options
    if Rails.env.production?
      { host: 'automation-calculations.net' }
    else
      {}
    end
  end

  protected

  def after_sign_in_path_for(resource_or_scope)
    if resource.sign_in_count < 2
      url_for resource.automation_scenarios.first
    else
      super
    end
  end

  def layout_selector
    devise_controller? ? 'auth' : 'application'
  end
end
