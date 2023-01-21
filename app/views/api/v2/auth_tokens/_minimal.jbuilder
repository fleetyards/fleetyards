# frozen_string_literal: true

json.cache! ["v2", auth_token] do
  json.partial!("api/v2/auth_tokens/base", auth_token:)
  json.partial! "api/shared/dates", record: auth_token
end
