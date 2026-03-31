# frozen_string_literal: true

json.items do
  json.array! @oauth_applications, partial: "admin/api/v1/oauth_applications/oauth_application", as: :oauth_application
end
json.partial! "api/shared/meta", result: @oauth_applications
