namespace :oauth do
  post :authorize, to: "authorizations#create", as: :create_authorization
  delete :authorize, to: "authorizations#create", as: :revoke_authorization
  post :token, to: "tokens#create", as: :token
  post :revoke, to: "tokens#destroy", as: :revoke
  post :introspect, to: "tokens#introspect", as: :introspect
  get :applications, to: "applications#index", as: :applications
  get "applications/:id", to: "applications#show", as: :application
  post :applications, to: "applications#create", as: :create_application
  put "applications/:id", to: "applications#update", as: :update_application
  delete "applications/:id", to: "applications#destroy", as: :destroy_application
  get "authorized-applications", to: "authorized_applications#index", as: :authorized_applications
  get "authorized-applications/:id", to: "authorized_applications#show", as: :authorized_application
  delete "authorized-applications/:id", to: "authorized_applications#destroy", as: :update_oauth_application
  get "token/info", to: "token_info#show", as: :token_info
end
