module Admin
  class UserPolicy < BasePolicy
    private def resource_access
      [:users]
    end
  end
end
