# frozen_string_literal: true

# Declare `before_action :check_inventory_transfers_feature` after the
# doorkeeper callbacks so unauthenticated requests still get a 401.
#
# The new flag composes with the three that already gate inventories rather
# than replacing them: a transfer touching a fleet inventory still needs
# `fleet_logistics`, and one touching a ship still needs `ship_inventories`.
# Otherwise this would be a way around them.
module InventoryTransfersFeatureConcern
  extend ActiveSupport::Concern

  private def check_inventory_transfers_feature
    return if feature_enabled?("inventory_transfers")

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end

  # Both ends of a transfer have to be open, and the two ends may be in
  # different families. Asked of the inventory rather than of the request,
  # because a crossing transfer is subject to both.
  private def inventory_feature_enabled?(inventory)
    case inventory
    when ::FleetInventory then feature_enabled?("fleet_logistics", inventory.fleet)
    when ::Inventory then feature_enabled?(inventory.vehicle? ? "ship_inventories" : "hangar_inventories")
    else false
    end
  end
end
