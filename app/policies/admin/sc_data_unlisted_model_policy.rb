module Admin
  class ScDataUnlistedModelPolicy < BasePolicy
    private def resource_access
      [:models]
    end
  end
end
