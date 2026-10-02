# frozen_string_literal: true

json.partial! "api/v1/fleet_squadrons/fleet_squadron", fleet_squadron: @fleet_squadron

# Only here, never in the list: `description` is the squadron's own page, and
# thirty of them would be carried by every grid that renders the short one.
json.description @fleet_squadron.description

if @viewer_squadron_role.present?
  json.viewer_role do
    json.partial! "api/v1/fleet_squadron_roles/base", fleet_squadron_role: @viewer_squadron_role
  end
end

json.capabilities do
  json.manage_members @squadron_capabilities.fetch(:manage_members)
  json.manage_ranks @squadron_capabilities.fetch(:manage_ranks)
end
