# frozen_string_literal: true

class FleetInventoryPolicy < FleetBasePolicy
  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:read"])
  end

  alias_rule :show?, to: :index?

  def create?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:create"])
  end

  def update?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:update"])
  end

  def destroy?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:inventories:delete"])
  end

  params_filter do |params|
    params.permit(:name, :description, :managed_by, :visibility, :location, :image)
  end
end
