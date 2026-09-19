# frozen_string_literal: true

# The fleet inventories a member may see.
#
# Every read of a fleet's inventories goes through here. The policy's relation
# scope is what keeps an officers-only store out of a plain member's sight, and
# a controller reaching for `@fleet.fleet_inventories` directly walks straight
# past it -- so a per-inventory lookup resolves through this and answers 404,
# rather than confirming the inventory exists with a 403.
module FleetInventoryScoped
  extend ActiveSupport::Concern

  private def visible_fleet_inventories(fleet = @fleet)
    authorized_scope(fleet.fleet_inventories, with: FleetInventoryPolicy, context: {fleet: fleet})
  end
end
