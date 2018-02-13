Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  get '/visitor', to: 'visitor#index'
  get '/visitor/create', to: 'visitor#create'
  get '/visitor/:id', to: 'visitor#show'
  delete 'visitor/:id', to: 'visitor#destroy'

  root to: 'home#index'
end
