Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  post 'automation_scenario/create'

  get 'automation_scenario/read'

  put 'automation_scenario/update'

  delete 'automation_scenario/delete'

  post 'visitor/create'

  get 'visitor/read'

  put 'visitor/update'

  delete 'visitor/delete'

  root to: 'home#index'
end
