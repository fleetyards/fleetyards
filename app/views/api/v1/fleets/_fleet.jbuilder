# frozen_string_literal: true

json.cache! ["v1", fleet] do
  json.partial!("api/v1/fleets/base", fleet:)
end

json.my_fleet(local_assigns.fetch(:my_fleet, false))

if local_assigns.fetch(:my_fleet, false)
  json.calendar_feed_token fleet.calendar_feed_token
end
