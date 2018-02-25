Rails.application.routes.draw do
  root to: 'home#index'

  devise_for :users

  resources :automation_scenarios

  get '/visitor', to: 'visitor#index'
  get '/visitor/create', to: 'visitor#create'
  get '/visitor/:id', to: 'visitor#show'
  delete 'visitor/:id', to: 'visitor#destroy'
end
