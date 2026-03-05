module Admin
  class DockPolicy < BasePolicy
    private def resource_access
      [:docks]
    end
  end
end
