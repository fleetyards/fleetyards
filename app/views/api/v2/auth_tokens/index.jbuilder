# frozen_string_literal: true

json.partial! 'api/shared/pagination_metadata', scope: @auth_tokens, model: AuthToken
json.items do
  json.array! @auth_tokens, partial: 'api/v2/auth_tokens/minimal', as: :auth_token
end
