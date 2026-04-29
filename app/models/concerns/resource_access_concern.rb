# frozen_string_literal: true

module ResourceAccessConcern
  extend ActiveSupport::Concern

  included do
    serialize :resource_access, coder: YAML
  end

  def resource_access
    value = super

    # Peel nested YAML layers from double/triple-serialized data
    while value.is_a?(String)
      value = YAML.safe_load(value, permitted_classes: [Array])
    end

    value || []
  end

  def has_access?(privileges)
    resource_access.any? do |access|
      privileges.include?(access)
    end
  end
end
