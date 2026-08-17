# frozen_string_literal: true

# Resolves the inventory of one of the current user's ships. Scoping the vehicle
# lookup to `current_resource_owner.vehicles` is the authorization boundary:
# somebody else's ship is a 404 before any policy runs.
module VehicleInventoryScoped
  extend ActiveSupport::Concern
  include InventoryScoped

  UUID_PREFIX = /\A[0-9a-f]{8}-[0-9a-f]{4}-/i

  # Reads see the ship's inventory as it would be — named after the ship, empty
  # and unsaved — until a first deposit brings it into existence.
  private def inventory
    @inventory ||= existing_inventory || Inventory.new(
      holder: current_resource_owner,
      vehicle: @vehicle,
      name: @vehicle.default_inventory_name
    )
  end

  private def provisioned_inventory
    return @inventory if @inventory&.persisted?

    @inventory = Inventory.provision_for(@vehicle, holder: current_resource_owner)
  end

  private def existing_inventory
    current_resource_owner.inventories.find_by(vehicle: @vehicle)
  end

  private def set_vehicle
    vehicle_id = params[:vehicle_id]

    @vehicle = if vehicle_id.match?(UUID_PREFIX)
      current_resource_owner.vehicles.find(vehicle_id)
    else
      current_resource_owner.vehicles.find_by!(serial: vehicle_id.upcase)
    end
  end

  private def inventory_policy
    HangarInventoryPolicy
  end

  private def inventory_item_policy
    HangarInventoryItemPolicy
  end
end
