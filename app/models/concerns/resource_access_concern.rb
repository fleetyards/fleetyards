# frozen_string_literal: true

module ResourceAccessConcern
  extend ActiveSupport::Concern

  included do
    serialize :resource_access, coder: YAML
  end

  # The admin UI saves privileges as strings while policies ask with symbols,
  # and an exact match let neither side satisfy the other.
  def has_access?(privileges)
    wanted = Array(privileges).map(&:to_s)

    resource_access&.any? do |access|
      wanted.include?(access.to_s)
    end
  end
end
