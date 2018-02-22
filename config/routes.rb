Rails.application.routes.draw do
  get 'automation_scenarios/create'

  get 'automation_scenarios/show'

  get 'automation_scenarios/update'

  get 'automation_scenarios/destroy'

  devise_for :users
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  get '/visitor', to: 'visitor#index'
  get '/visitor/create', to: 'visitor#create'
  get '/visitor/:id', to: 'visitor#show'
  delete 'visitor/:id', to: 'visitor#destroy'

  root to: 'home#index'
end
