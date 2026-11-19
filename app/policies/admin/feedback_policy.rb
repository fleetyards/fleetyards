module Admin
  class FeedbackPolicy < BasePolicy
    private def resource_access
      [:feedback]
    end
  end
end
