# frozen_string_literal: true

# The fleet inventories a member may reach.
#
# Every read of a fleet's inventories goes through one of these. A controller
# reaching for `@fleet.fleet_inventories` directly walks straight past the
# visibility rule -- so a per-inventory lookup resolves through `visible_` and
# answers 404, rather than confirming the inventory exists with a 403.
module FleetInventoryScoped
  extend ActiveSupport::Concern

  # Visibility only. Every caller authorizes the action afterwards, and the
  # privilege lists are independent -- a role may carry
  # `fleet:inventories:update` without `:read` -- so the lookup must not decide
  # the write by refusing to find the record.
  private def visible_fleet_inventories(fleet = @fleet)
    authorized_scope(fleet.fleet_inventories, with: FleetInventoryPolicy,
      context: {fleet: fleet}, as: :visible)
  end

  # The list itself, which is a read and so carries the read gate too.
  private def readable_fleet_inventories(fleet = @fleet)
    authorized_scope(fleet.fleet_inventories, with: FleetInventoryPolicy, context: {fleet: fleet})
  end
end
