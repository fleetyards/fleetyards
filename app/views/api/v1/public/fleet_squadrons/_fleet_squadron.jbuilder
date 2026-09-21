# frozen_string_literal: true

json.cache! ["v1", "public", fleet_squadron] do
  json.partial!("api/v1/public/fleet_squadrons/base", fleet_squadron:)
end

# Outside the fragment, for the reason the fleet's own partial gives.
json.member_count fleet_squadron.member_count
