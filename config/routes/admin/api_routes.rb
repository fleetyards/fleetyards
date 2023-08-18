# frozen_string_literal: true

namespace :api do
  draw "admin/api/v1_routes"

  get "docs" => "docs#index", :as => :docs
  get ":api_version/schema" => "schema#index", :as => :schema
end
