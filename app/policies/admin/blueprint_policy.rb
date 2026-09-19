module Admin
  class BlueprintPolicy < BasePolicy
    private def resource_access
      [:blueprints]
    end
  end
end
