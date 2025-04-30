module Public
  class FleetPolicy < FleetBasePolicy
    def show?
      fleet_membership&.accepted? || record.public_fleet?
    end
  end
end
