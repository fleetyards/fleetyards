# frozen_string_literal: true

# Fleets cannot add, reorder or re-privilege their roles; what they can do is
# call them something else.
class FleetRolePolicy < FleetBasePolicy
  UPDATE_PRIVILEGES = ["fleet:manage", "fleet:roles:manage", "fleet:roles:update"].freeze

  # The permanent Admin role names who runs the fleet; an officer holding
  # fleet:roles:manage renames the roles below it.
  def update?
    return false unless accepted_fleet_membership&.has_access?(UPDATE_PRIVILEGES)
    return true unless record.try(:permanent?)

    accepted_fleet_membership.has_access?(["fleet:manage"])
  end
end
