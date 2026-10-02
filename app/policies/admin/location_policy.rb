module Admin
  class LocationPolicy < BasePolicy
    private def resource_access
      [:locations]
    end
  end
end
