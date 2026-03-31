module Admin
  class ModelLoanerPolicy < BasePolicy
    private def resource_access
      [:model_loaners]
    end
  end
end
