module Admin
  class ModelHardpointPolicy < BasePolicy
    private def resource_access
      [:model_hardpoints]
    end
  end
end
