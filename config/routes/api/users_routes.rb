resources :users, only: [] do
  collection do
    post :signup
    post :confirm
    post "check-email"
    post "check-username"

    get :me
    put "me", to: "users#update"
    delete "me", to: "users#destroy"
    put "account", to: "users#update_account"

    get ":username", to: "public/users#show"
  end
end

namespace :public do
  resources :users, param: :username, only: %i[show]
end
