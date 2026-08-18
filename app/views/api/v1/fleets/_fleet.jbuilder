# frozen_string_literal: true

json.cache! ["v1", fleet] do
  json.partial!("api/v1/fleets/base", fleet:)
end

json.my_fleet(local_assigns.fetch(:my_fleet, false))

# Outside the cache block above on purpose: flag state is not part of the fleet
# record, so a cached copy would keep serving the old answer until the fleet
# itself changed.
json.features fleet.features

if local_assigns.fetch(:my_fleet, false)
  json.calendar_feed_token fleet.calendar_feed_token
end
