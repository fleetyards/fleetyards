# frozen_string_literal: true

module Admin
  class ModelUpgradePolicy < BasePolicy
    private def resource_access
      [:model_upgrades]
    end
  end
end
