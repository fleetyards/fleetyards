# frozen_string_literal: true

json.cache! ['v1', user] do
  json.username user.username
  json.avatar user.avatar.small.url
end
