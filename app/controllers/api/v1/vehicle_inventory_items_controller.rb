# frozen_string_literal: true

module Api
  module V1
    class VehicleInventoryItemsController < ::Api::BaseController
      include ShipInventoriesFeatureConcern
      include VehicleInventoryScoped
      include InventoryScoped::ItemActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy import]

      before_action :check_ship_inventories_feature
      before_action :set_vehicle
      before_action :set_inventory_item, only: %i[update destroy]

      private def validation_error_scope
        "vehicle_inventory_items"
      end
    end
  end
end
