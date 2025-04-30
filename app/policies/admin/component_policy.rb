module Admin
  class ComponentPolicy < BasePolicy
    private def resource_access
      [:components]
    end
  end
end
