# frozen_string_literal: true

json.id oauth_application.id
json.name oauth_application.name
json.uid oauth_application.uid
json.secret oauth_application.secret
json.confidential oauth_application.confidential
json.redirect_uri oauth_application.redirect_uri
json.scopes oauth_application.scopes.to_s
json.owner_name oauth_application.owner&.username
json.owner_id oauth_application.owner_id
json.state oauth_application.aasm_state
json.rejection_reason oauth_application.rejection_reason
json.approved_at oauth_application.approved_at
json.rejected_at oauth_application.rejected_at
json.reviewed_by_name oauth_application.reviewed_by&.username
if oauth_application.logo.attached?
  json.logo do
    json.partial! "api/v1/shared/file", record: oauth_application, attr: :logo
  end
end
json.partial! "api/shared/dates", record: oauth_application
