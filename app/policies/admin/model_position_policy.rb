module Admin
  class ModelPositionPolicy < BasePolicy
    private def resource_access
      [:model_positions]
    end
  end
end
