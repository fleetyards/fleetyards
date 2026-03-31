module Admin
  class ModelHardpointLoadoutPolicy < BasePolicy
    private def resource_access
      [:model_hardpoints]
    end
  end
end
