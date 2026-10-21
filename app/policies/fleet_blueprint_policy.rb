# frozen_string_literal: true

# What a fleet may read of the recipes its members hold.
#
# There is no record of its own here -- a fleet's blueprint list is a join over
# its members' markers, not a table -- so this is a policy about the fleet, and
# the privilege is declared on `UserBlueprint`.
class FleetBlueprintPolicy < FleetBasePolicy
  alias_rule :wanted?, to: :index?

  def index?
    accepted_fleet_membership&.has_access?(["fleet:manage", "fleet:blueprints:read"])
  end
end
