# frozen_string_literal: true

# The role list is what a role is picked from, so it is readable by whoever may
# pick one: the join role belongs to whoever may hand out invites, the member
# role to whoever manages the fleet's Discord settings.
class FleetDiscordRolePolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?([
      "fleet:manage",
      "fleet:invites:manage",
      "fleet:invites:create",
      "fleet:notifications:manage"
    ]) || false
  end
end
