oauth_options = {
  host: Rails.configuration.app.domain,
  constraints: ->(req) { req.subdomain.blank? || %w[admin api docs].exclude?(req.subdomain) }
}.compact

use_doorkeeper_openid_connect

namespace :oauth, **oauth_options do
  get :authorize, to: "/frontend/base#index", constraints: ->(req) { req.format.html? }, as: :authorization
  get :authorize, to: "/oauth/authorizations#new", constraints: ->(req) { !req.format.html? }
  post :authorize, to: "/oauth/authorizations#create"
  delete :authorize, to: "/oauth/authorizations#destroy"

  post :token, to: "/doorkeeper/tokens#create"
  post :revoke, to: "/doorkeeper/tokens#destroy"
  post :introspect, to: "/doorkeeper/tokens#introspect"

  scope format: true, constraints: {format: "yaml"} do
    get ":api_version/schema" => "schema#index", :as => :schema
  end
end
