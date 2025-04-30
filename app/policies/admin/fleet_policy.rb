module Admin
  class FleetPolicy < BasePolicy
    private def resource_access
      [:fleets]
    end
  end
end
