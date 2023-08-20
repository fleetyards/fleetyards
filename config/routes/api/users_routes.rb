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

    get :current, to: "users#me" # DEPRECATED
    put :current, to: "users#update" # DEPRECATED
    delete :current, to: "users#destroy" # DEPRECATED

    get ":username", to: "users#public"

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
