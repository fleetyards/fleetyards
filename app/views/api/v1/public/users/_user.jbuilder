# frozen_string_literal: true

json.cache! ["v2", user, user.rsi_handle_verification_cache_key, Date.current.beginning_of_month] do
  json.partial!("api/v1/public/users/base", user:)
end
