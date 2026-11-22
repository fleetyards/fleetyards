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

  private def leads_a_squadron?
    return false unless accepted_fleet_membership.has_access?(FleetSquadron::READ_PRIVILEGES)

    FleetSquadronMembership
      .joins(:fleet_squadron_role)
      .where(fleet_membership: accepted_fleet_membership)
      .where(fleet_squadron_roles: {key: FleetSquadronRole::SQUADRON_EDITOR_KEYS})
      .exists?
  end
end
