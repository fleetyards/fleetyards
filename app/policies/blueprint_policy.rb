# frozen_string_literal: true

# The catalogue itself is public and its reads skip authorization entirely.
# What is left to decide is the personal marker, and the only question there is
# whether there is somebody to mark it for -- a recipe is not owned by anyone
# in a way that could refuse.
class BlueprintPolicy < ApplicationPolicy
  alias_rule :unown?, to: :own?

  def own?
    user.present?
  end
end
