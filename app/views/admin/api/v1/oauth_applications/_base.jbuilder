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
json.partial! "api/shared/dates", record: oauth_application
