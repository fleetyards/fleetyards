# frozen_string_literal: true

# A transfer touching a fleet inventory is gated by the flag fleet inventories
# already ride on, `fleet_logistics`. A person's own inventories, hangar and
# ship alike, are open to everyone.
module InventoryTransfersFeatureConcern
  extend ActiveSupport::Concern

  # Both ends of a transfer have to be open, and the two ends may be in
  # different families. Asked of the inventory rather than of the request,
  # because a crossing transfer is subject to both.
  private def inventory_feature_enabled?(inventory)
    case inventory
    when ::FleetInventory then feature_enabled?("fleet_logistics", inventory.fleet)
    when ::Inventory then true
    else false
    end
  end
end
