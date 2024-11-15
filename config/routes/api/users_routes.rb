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

    resource :two_factor, path: "two-factor", only: [] do
      collection do
        get :qrcode
        post :start
        post :enable
        post :disable
        post "generate-backup-codes" => "two_factors#generate_backup_codes"
      end
    end
  end
end

namespace :public do
  resources :users, param: :username, only: %i[show]
end
