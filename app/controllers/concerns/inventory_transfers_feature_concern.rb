# frozen_string_literal: true

# A transfer is gated by the flags its inventories already ride on: one
# touching a fleet inventory needs `fleet_logistics`, and one touching a ship
# needs `ship_inventories`.
module InventoryTransfersFeatureConcern
  extend ActiveSupport::Concern

  # Both ends of a transfer have to be open, and the two ends may be in
  # different families. Asked of the inventory rather than of the request,
  # because a crossing transfer is subject to both. A person's inventory is
  # asked of its holder: that is the caller for their own, and the author for
  # a contract's hangar destination, which a contractor delivers into.
  private def inventory_feature_enabled?(inventory)
    case inventory
    when ::FleetInventory then feature_enabled?("fleet_logistics", inventory.fleet)
    when ::Inventory
      Flipper.enabled?(inventory.vehicle? ? "ship_inventories" : "hangar_inventories", inventory.holder)
    else false
    end
  end
end
