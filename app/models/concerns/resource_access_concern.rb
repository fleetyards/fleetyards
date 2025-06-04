# frozen_string_literal: true

module ResourceAccessConcern
  extend ActiveSupport::Concern

  included do
    serialize :resource_access, coder: YAML
  end

  def has_access?(privileges)
    resource_access&.any? do |access|
      privileges.include?(access)
    end
  end
end
