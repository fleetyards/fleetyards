module Admin
  class ModelPaintPolicy < BasePolicy
    private def resource_access
      [:model_paints]
    end
  end
end
