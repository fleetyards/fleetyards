module Admin
  class HardpointPolicy < BasePolicy
    private def resource_access
      [:models]
    end
  end
end
