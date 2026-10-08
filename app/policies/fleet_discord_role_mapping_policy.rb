# frozen_string_literal: true

# Which Discord role each rank hands out is part of the fleet's Discord setup,
# so it belongs to whoever manages that, not to whoever may rename ranks.
class FleetDiscordRoleMappingPolicy < FleetBasePolicy
  def show?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:notifications:manage"]) || false
  end

  alias_rule :update?, to: :show?
end
