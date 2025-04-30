class FleetVehiclePolicy < FleetBasePolicy
  alias_rule :export?, :fleetchart?, to: :index?

  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:vehicles:manage", "fleet:vehicles:read"])
  end
end
