module Admin
  class SupporterContributionPolicy < BasePolicy
    private def resource_access
      [:supporters]
    end
  end
end
