module Admin
  class UserPolicy < BasePolicy
    # The picker list, which the feature page needs to grant a flag to a user.
    def options?
      user.has_access?([:users, :features])
    end

    private def resource_access
      [:users]
    end
  end
end
