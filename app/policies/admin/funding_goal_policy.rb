module Admin
  class FundingGoalPolicy < BasePolicy
    private def resource_access
      [:supporters]
    end
  end
end
