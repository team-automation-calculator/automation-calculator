Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :iterations

    scope module: 'v1', as: 'v1', constraints: Constraint.new(1) do
      resource :visitor, only: :create
      post 'sign_in', to: 'user_sessions#create'
      post 'sign_up', to: 'users#create'

      resources :automation_scenarios do
        resources :solutions, shallow: true
      end

      root to: 'roots#show'
    end
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  resources :automation_scenarios
  resource :visitor, only: %i[show create]

  get '/health', to: 'health_check#health', defaults: { format: 'json' }

  root to: 'automation_scenarios#index'
end
