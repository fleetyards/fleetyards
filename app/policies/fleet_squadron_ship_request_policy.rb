# frozen_string_literal: true

# Asking for a member's ship is for whoever manages the squadron's roster;
# answering is the member's alone. Either side may take a request back.
class FleetSquadronShipRequestPolicy < FleetBasePolicy
  authorize :fleet_squadron, optional: true

  def index?
    in_squadron? || manages_roster?
  end

  def create?
    manages_roster?
  end

  def accept?
    own?
  end

  # Declined by the member, or withdrawn by the roster.
  def destroy?
    own? || manages_roster?
  end

  def manages_roster?
    squadron = record.try(:fleet_squadron) || fleet_squadron
    return false if squadron.blank?

    allowed_to?(:create?, FleetSquadronMembership.new(fleet_squadron: squadron), with: FleetSquadronMembershipPolicy)
  end

  private def own?
    accepted_fleet_membership.present? &&
      record.try(:fleet_squadron_membership)&.fleet_membership_id == accepted_fleet_membership.id
  end

  private def in_squadron?
    accepted_fleet_membership.present? && fleet_squadron.present? &&
      fleet_squadron.fleet_squadron_memberships.exists?(fleet_membership_id: accepted_fleet_membership.id)
  end
end
