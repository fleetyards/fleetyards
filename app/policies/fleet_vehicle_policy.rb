class FleetVehiclePolicy < FleetBasePolicy
  alias_rule :export?, :export_hangar_link?, :fleetchart?, to: :index?

  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:vehicles:manage", "fleet:vehicles:read"])
  end
end
