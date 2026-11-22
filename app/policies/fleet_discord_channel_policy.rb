# frozen_string_literal: true

# The channel list is what a channel is picked from, so it is readable by
# whoever may pick one: a squadron's channel belongs to whoever may edit the
# squadron, the fleet's announcement channel to whoever manages its
# notifications. A squadron's Leader edits that squadron without any fleet
# privilege, so leading one is enough.
class FleetDiscordChannelPolicy < FleetBasePolicy
  def index?
    return false if accepted_fleet_membership.blank?

    accepted_fleet_membership.has_access?([
      *FleetSquadron::MANAGE_PRIVILEGES,
      "fleet:squadrons:create",
      "fleet:squadrons:update",
      "fleet:notifications:manage"
    ]) || leads_a_squadron?
  end

  # A fleet that switched squadrons off keeps its old rank rows, and they must
  # not go on opening the channel list.
  private def leads_a_squadron?
    return false unless accepted_fleet_membership.fleet.squadrons_enabled?
    return false unless accepted_fleet_membership.has_access?(FleetSquadron::READ_PRIVILEGES)

    FleetSquadronMembership.editing_their_squadron.exists?(fleet_membership: accepted_fleet_membership)
  end
end
