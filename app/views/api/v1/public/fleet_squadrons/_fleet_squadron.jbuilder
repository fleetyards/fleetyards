# frozen_string_literal: true

json.cache! ["v1", "public", fleet_squadron] do
  json.partial!("api/v1/public/fleet_squadrons/base", fleet_squadron:)
end

# Outside the fragment, for the reason the fleet's own partial gives. A
# headcount is one of the fleet's numbers, so it is shown only where the
# fleet's stats are.
json.member_count(@show_member_counts ? fleet_squadron.member_count : nil)
