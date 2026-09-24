# frozen_string_literal: true

# Who may see and change who is in a squadron.
#
# Separate from `FleetSquadronPolicy` because the two answer different
# questions: deciding which squadrons exist is an admin's, posting people to
# them is an officer's. A role carrying `fleet:squadrons:members:manage` alone
# can fill a squadron it cannot rename.
class FleetSquadronMembershipPolicy < FleetBasePolicy
  # A squadron's roster is the fleet's roster narrowed, so it asks for both
  # reads: seeing that a squadron exists is not seeing who is in it.
  def index?
    return false unless accepted_fleet_membership&.has_access?(FleetSquadron::READ_PRIVILEGES)

    accepted_fleet_membership.has_access?(["fleet:manage", "fleet:memberships:manage", "fleet:memberships:read"])
  end

  def create?
    accepted_fleet_membership&.has_access?(FleetSquadron::MEMBERS_MANAGE_PRIVILEGES) || false
  end

  def destroy?
    create?
  end

  def update?
    create?
  end
end
