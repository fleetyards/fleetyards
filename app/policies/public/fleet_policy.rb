module Public
  class FleetPolicy < FleetBasePolicy
    def show?
      fleet_membership&.accepted? || record.public_fleet? || record.public_fleet_stats?
    end

    def show_stats?
      fleet_membership&.accepted? || record.public_fleet_stats?
    end
  end
end
