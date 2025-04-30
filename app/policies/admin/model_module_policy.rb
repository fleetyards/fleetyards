module Admin
  class ModelModulePolicy < BasePolicy
    private def resource_access
      [:model_modules]
    end
  end
end
