# frozen_string_literal: true

module Admin
  class FeaturePolicy < BasePolicy
    private def resource_access
      [:features]
    end
  end
end
