# frozen_string_literal: true

resources :users, only: [] do
  collection do
    get :current
    post :signup
    post :confirm
    post 'check-email'
    post 'check-username'
    put 'current' => 'users#update'
    patch 'current' => 'users#update'
    put 'current-account' => 'users#update_account'
    patch 'current-account' => 'users#update_account'
    delete 'current' => 'users#destroy'

    resource :two_factor, path: 'two-factor', only: [] do
      collection do
        get :qrcode
        post :start
        post :enable
        post :disable
        post 'generate-backup-codes' => 'two_factors#generate_backup_codes'
      end
    end

    resources :auth_tokens, path: 'auth-tokens', except: %i[show new edit]

    get ':username' => 'users#public'
  end
end

resource :password, only: [:update] do
  collection do
    post 'request' => 'passwords#request_email'
    patch 'update' => 'passwords#update'
    put 'update' => 'passwords#update'
    patch 'update/:reset_password_token' => 'passwords#update_with_token'
    put 'update/:reset_password_token' => 'passwords#update_with_token'
  end
end
