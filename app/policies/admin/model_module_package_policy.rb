# frozen_string_literal: true

module Admin
  class ModelModulePackagePolicy < BasePolicy
    private def resource_access
      [:model_module_packages]
    end
  end
end
