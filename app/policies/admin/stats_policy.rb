module Admin
  class StatsPolicy < BasePolicy
    private def resource_access
      [:stats]
    end
  end
end
