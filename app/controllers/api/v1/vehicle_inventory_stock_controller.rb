# frozen_string_literal: true

module Api
  module V1
    class VehicleInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include VehicleInventoryScoped
      include InventoryScoped::StockActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :check_hangar_inventories_feature
      before_action :set_vehicle
      before_action :set_stock_item, only: %i[show update destroy]

      # Stock positions are rolled-up ledger entries, so their failures speak in
      # the entry scope.
      private def validation_error_scope
        "vehicle_inventory_items"
      end
    end
  end
end
