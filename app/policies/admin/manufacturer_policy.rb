module Admin
  class ManufacturerPolicy < BasePolicy
    private def resource_access
      [:manufacturers]
    end
  end
end
