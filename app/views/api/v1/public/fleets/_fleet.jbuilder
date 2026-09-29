# frozen_string_literal: true

# Its own cache key: the members' copy carries the SID as typed, and a visitor
# only sees one the fleet has proved -- anyone can type any SID.
json.cache! ["v2", "public", fleet, fleet.rsi_verified?] do
  json.partial!("api/v1/fleets/base", fleet:, visitor: true)
end

# Outside the cache for the reason the fleet's own partial gives. A visitor's
# page gates the sections a fleet has switched on by these, as a member's does.
json.features fleet.features
