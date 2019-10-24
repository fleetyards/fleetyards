# frozen_string_literal: true

json.cache! ['v1', user] do
  json.username user.username
  json.rsi_handle user.rsi_handle if user.rsi_verified?
end
