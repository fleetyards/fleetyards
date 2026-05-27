module Admin
  class ModelSnubCraftPolicy < BasePolicy
    private def resource_access
      [:model_snub_crafts]
    end
  end
end
