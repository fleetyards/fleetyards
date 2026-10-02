# frozen_string_literal: true

# Fleets cannot add, reorder or re-privilege their roles; what they can do is
# call them something else.
class FleetRolePolicy < FleetBasePolicy
  UPDATE_PRIVILEGES = ["fleet:manage", "fleet:roles:manage", "fleet:roles:update"].freeze

  def update?
    accepted_fleet_membership&.has_access?(UPDATE_PRIVILEGES) || false
  end
end
