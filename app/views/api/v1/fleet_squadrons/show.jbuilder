# frozen_string_literal: true

json.partial! "api/v1/fleet_squadrons/fleet_squadron", fleet_squadron: @fleet_squadron

# Only here, never in the list: `description` is the squadron's own page, and
# thirty of them would be carried by every grid that renders the short one.
json.description @fleet_squadron.description

# The banner is the profile's own, so it rides with the page that draws it.
if @fleet_squadron.header.attached?
  json.header do
    json.partial! "api/v1/shared/file", record: @fleet_squadron, attr: :header
  end
else
  json.header nil
end
