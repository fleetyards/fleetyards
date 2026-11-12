# frozen_string_literal: true

json.cache! ["v1", fleet_squadron] do
  json.partial!("api/v1/fleet_squadrons/base", fleet_squadron:)
end

# Outside the fragment. Adding or removing a member touches the squadron, so
# that much the key would catch -- but a member leaving the fleet is a discard,
# which leaves the join row in place and never touches anything here. Counting
# per squadron costs one indexed count; serving a roster that has changed does
# not cost anything until somebody notices.
json.member_count fleet_squadron.member_count

# Only while the squadron has flights, from the count its list took for the
# whole page.
flight_counts = local_assigns[:flight_counts]
if flight_counts && fleet_squadron.flights_enabled?
  json.flight_count flight_counts.fetch(fleet_squadron.id, 0)
end
