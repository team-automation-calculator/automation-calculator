Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  get 'automation_scenario/create'

  get 'automation_scenario/read'

  get 'automation_scenario/update'

  get 'automation_scenario/delete'

  get 'visitor/create'

  get 'visitor/read'

  get 'visitor/update'

  get 'visitor/delete'

  root to: 'home#index'
end
