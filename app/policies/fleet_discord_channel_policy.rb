# frozen_string_literal: true

# The channel list is what a channel is picked from, so it is readable by
# whoever may pick one: a squadron's channel belongs to whoever may edit the
# squadron, the fleet's announcement channel to whoever manages its
# notifications.
class FleetDiscordChannelPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?([
      *FleetSquadron::MANAGE_PRIVILEGES,
      "fleet:squadrons:create",
      "fleet:squadrons:update",
      "fleet:notifications:manage"
    ]) || false
  end
end
