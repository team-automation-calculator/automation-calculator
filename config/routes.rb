Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  resources :automation_scenarios
  resources :solutions

  get '/visitors', to: 'visitors#index'
  get '/visitors/create', to: 'visitors#create'
  get '/visitors/:id', to: 'visitors#show'
  delete 'visitors/:id', to: 'visitors#destroy'
  get '/health', to: 'health_check#health', defaults: { format: 'json' }

  root to: 'home#index'
end
