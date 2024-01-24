oauth_options = {
  host: Rails.configuration.app.domain,
  constraints: ->(req) { req.subdomain.blank? || %w[admin api docs].exclude?(req.subdomain) }
}.compact

namespace :oauth, **oauth_options do
  get :authorize, to: "/frontend/base#index", constaints: ->(req) { req.format.html? }

  # use_doorkeeper scope: "" do
  #   skip_controllers :applications, :authorized_applications, :tokens, :token_info
  #   controllers authorizations: "authorizations"
  # end

  # resources :tokens, only: [:create, :destroy]
  # resources :applications, only: [:index, :show, :create, :update, :destroy]
  # resources :authorized_applications, path: "authorized-applications", only: [:index, :show, :destroy]
end
