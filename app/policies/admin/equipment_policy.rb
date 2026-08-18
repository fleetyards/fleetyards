module Admin
  class EquipmentPolicy < BasePolicy
    private def resource_access
      [:equipment]
    end
  end
end
