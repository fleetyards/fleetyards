# frozen_string_literal: true

# Narrowing a fleet's own list to what the viewer's squadrons allow.
#
# The lists that carry this build their scopes by hand rather than through
# `authorized_scope`, so the restriction is applied where the scope is built
# and `show?` refuses the same records one at a time. The two have to agree,
# and the policy tests are what hold them together.
module SquadronVisibilityConcern
  extend ActiveSupport::Concern

  # The viewer's accepted membership in `@fleet`, or nil -- for a signed-out
  # reader, or somebody who is not in this fleet. Memoised against the query
  # rather than the result, so a nil answer is not asked for twice.
  private def current_fleet_membership
    return @current_fleet_membership if defined?(@current_fleet_membership)

    @current_fleet_membership = current_resource_owner
      &.fleet_memberships
      &.kept
      &.accepted
      &.find_by(fleet_id: @fleet&.id)
  end

  private def narrow_to_squadron_access(scope)
    scope.for_squadrons_of(current_fleet_membership)
  end
end
