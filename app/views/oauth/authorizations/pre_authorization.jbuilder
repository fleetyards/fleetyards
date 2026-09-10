json.client_id @pre_auth.client.uid
json.client_name @pre_auth.client.name
json.redirect_uri @pre_auth.redirect_uri
# `client` is Doorkeeper's wrapper; the record carrying the attachment is the
# application behind it.
if @pre_auth.client.application.logo.attached?
  json.client_logo do
    json.partial! "api/v1/shared/file", record: @pre_auth.client.application, attr: :logo
  end
end
json.state @pre_auth.state
json.response_type @pre_auth.response_type
json.response_mode @pre_auth.response_mode
json.scope @pre_auth.scope
json.code_challenge @pre_auth.code_challenge
json.code_challenge_method @pre_auth.code_challenge_method
json.scopes @pre_auth.scopes do |scope|
  json.name scope
  json.description I18n.t(scope, scope: [:doorkeeper, :scopes])
end
