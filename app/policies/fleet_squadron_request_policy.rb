# frozen_string_literal: true

# Asking to join a squadron is the member's own business; answering is for
# whoever manages the roster -- the same people who may add somebody directly,
# so a squadron rank answers its own squadron's requests.
class FleetSquadronRequestPolicy < FleetBasePolicy
  authorize :fleet_squadron, optional: true

  def index?
    manages_roster?
  end

  def create?
    own?
  end

  def accept?
    manages_roster?
  end

  # Withdrawn by the member who asked, or declined by the roster.
  def destroy?
    own? || manages_roster?
  end

  private def own?
    accepted_fleet_membership.present? && record.try(:fleet_membership_id) == accepted_fleet_membership.id
  end

  private def manages_roster?
    squadron = record.try(:fleet_squadron) || fleet_squadron
    return false if squadron.blank?

    allowed_to?(:create?, FleetSquadronMembership.new(fleet_squadron: squadron), with: FleetSquadronMembershipPolicy)
  end
end
