class ApplicationController < ActionController::Base
  include Visitable
  protect_from_forgery with: :exception
  layout :layout_selector

  def default_url_options
    if Rails.env.production?
      { host: ENV['APP_HOSTNAME'] }
    else
      {}
    end
  end

  def authenticate_user_or_visitor!
    authenticate_user! if current_visitor.blank?
  end

  protected

  # Devise may pass a scope symbol (e.g. :user) instead of a record, and a
  # user may have deleted all of their scenarios; fall back to Devise's
  # default in either case.
  def after_sign_in_path_for(resource_or_scope)
    scenario = first_sign_in_scenario(resource_or_scope)
    scenario ? url_for(scenario) : super
  end

  def first_sign_in_scenario(resource_or_scope)
    return unless resource_or_scope.is_a?(User)
    return unless resource_or_scope.sign_in_count < 2

    resource_or_scope.automation_scenarios.order(:created_at).first
  end

  def layout_selector
    devise_controller? ? 'auth' : 'application'
  end
end
