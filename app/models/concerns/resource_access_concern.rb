# frozen_string_literal: true

module ResourceAccessConcern
  extend ActiveSupport::Concern

  included do
    serialize :resource_access, coder: YAML
  end

  def has_access?(privileges)
    access_list = resource_access
    access_list = YAML.safe_load(access_list, permitted_classes: [Array]) if access_list.is_a?(String)

    Array(access_list).any? do |access|
      privileges.include?(access)
    end
  end
end
