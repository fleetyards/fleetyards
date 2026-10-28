module Admin
  class RafflePolicy < BasePolicy
    private def resource_access
      [:raffles]
    end
  end
end
