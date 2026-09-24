# frozen_string_literal: true

json.cache! ["v1", fleet] do
  json.partial!("api/v1/fleets/base", fleet:)
end

# Outside the cache for the reason the fleet's own partial gives. A visitor's
# page gates the sections a fleet has switched on by these, as a member's does.
json.features fleet.features
