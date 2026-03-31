module Admin
  class CargoHoldPolicy < BasePolicy
    private def resource_access
      [:cargo_holds]
    end
  end
end
