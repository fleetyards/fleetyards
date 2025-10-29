module Admin
  class ModelPolicy < BasePolicy
    private def resource_access
      [:models]
    end
  end
end
