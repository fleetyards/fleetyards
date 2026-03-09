# frozen_string_literal: true

json.id application.id
json.name application.name
json.uid application.uid
json.confidential application.confidential
json.redirect_uri application.redirect_uri
json.scopes application.scopes.to_s
json.partial! "api/shared/dates", record: application
