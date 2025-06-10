module Admin
  class VehiclePolicy < BasePolicy
    private def resource_access
      [:vehicles]
    end
  end
end
