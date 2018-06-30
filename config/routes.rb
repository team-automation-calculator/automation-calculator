Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :iterations
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  resources :automation_scenarios
  resource :visitor, only: :create

  get '/health', to: 'health_check#health', defaults: { format: 'json' }

  root to: 'automation_scenarios#index'
end
