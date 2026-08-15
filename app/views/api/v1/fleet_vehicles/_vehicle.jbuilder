# frozen_string_literal: true

# Owner contact links live here rather than in the shared public partial: this
# list is scoped to fleet members by FleetVehiclePolicy, while the same partial
# also renders public hangars, where an owner shares a name and nothing more.
json.cache! ["v1-fleet", vehicle.model, vehicle.user, vehicle] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)

  unless vehicle.user.hide_owner?
    json.user_discord_profile_url vehicle.user.discord_profile_url
    json.user_citizenid_profile_url vehicle.user.citizenid_profile_url
  end
end
