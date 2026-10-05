module Admin
  class FleetPolicy < BasePolicy
    # The picker list, which the feature page needs to grant a flag to a fleet.
    # It names fleets and nothing else, which the feature's own actor list
    # already shows that admin.
    def options?
      user.has_access?([:fleets, :features])
    end

    private def resource_access
      [:fleets]
    end
  end
end
