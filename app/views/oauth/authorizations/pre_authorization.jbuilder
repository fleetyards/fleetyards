json.client_id @pre_auth.client.uid
json.client_name @pre_auth.client.name
json.redirect_uri @pre_auth.redirect_uri
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
