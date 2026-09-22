# frozen_string_literal: true

json.partial! "api/v1/fleet_squadrons/fleet_squadron", fleet_squadron: @fleet_squadron

# Only here, never in the list: `description` is the squadron's own page, and
# thirty of them would be carried by every grid that renders the short one.
json.description @fleet_squadron.description
