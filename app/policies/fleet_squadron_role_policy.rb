# frozen_string_literal: true

# The fleet's names for its squadron ranks. Anyone who can see squadrons can
# read them; renaming one is deciding how every squadron is organised, which is
# the same call as deciding which squadrons exist.
class FleetSquadronRolePolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(FleetSquadron::READ_PRIVILEGES) || false
  end

  def update?
    accepted_fleet_membership&.has_access?(FleetSquadron::MANAGE_PRIVILEGES) || false
  end
end
