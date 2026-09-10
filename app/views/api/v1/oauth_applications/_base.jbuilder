# frozen_string_literal: true

json.id application.id
json.name application.name
json.uid application.uid
json.confidential application.confidential
json.redirect_uri application.redirect_uri
json.scopes application.scopes.to_s
json.state application.aasm_state
json.rejection_reason application.rejection_reason
if application.logo.attached?
  json.logo do
    json.partial! "api/v1/shared/file", record: application, attr: :logo
  end
end
json.partial! "api/shared/dates", record: application
