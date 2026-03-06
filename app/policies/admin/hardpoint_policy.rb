module Admin
  class HardpointPolicy < BasePolicy
    private def resource_access
      [:model_hardpoints]
    end
  end
end
