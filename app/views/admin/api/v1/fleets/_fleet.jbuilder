# frozen_string_literal: true

json.cache! ["v2", fleet, fleet.rsi_verification_cache_key] do
  json.partial!("admin/api/v1/fleets/base", fleet:)
end
