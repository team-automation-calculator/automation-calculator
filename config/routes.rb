Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  resources :automation_scenarios
  resources :solutions

  get '/visitor', to: 'visitor#index'
  get '/visitor/create', to: 'visitor#create'
  get '/visitor/:id', to: 'visitor#show'
  delete 'visitor/:id', to: 'visitor#destroy'
  get '/health', to: 'health_check#health', defaults: { format: 'json' }

  root to: 'home#index'
end
