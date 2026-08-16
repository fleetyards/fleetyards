# frozen_string_literal: true

module Api
  module V1
    class HangarAllInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include ShipInventoriesFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      before_action :check_hangar_inventories_feature

      def index
        authorize! with: HangarInventoryItemPolicy, to: :index?

        inventory_ids = filtered_inventories.pluck(:id)

        @stock = InventoryItem
          .where(inventory_id: inventory_ids)
          .joins(:inventory)
          .select(
            "inventory_items.name",
            "inventory_items.category",
            "inventory_items.unit",
            "MIN(inventory_items.quality) AS quality_min",
            "MAX(inventory_items.quality) AS quality_max",
            "inventories.name AS inventory_name",
            "inventories.slug AS inventory_slug",
            "SUM(CASE WHEN inventory_items.entry_type = 0 THEN inventory_items.quantity ELSE -inventory_items.quantity END) AS net_quantity"
          )
          .group(
            "inventory_items.name",
            "inventory_items.category",
            "inventory_items.unit",
            "inventories.name",
            "inventories.slug"
          )
          .having("SUM(CASE WHEN inventory_items.entry_type = 0 THEN inventory_items.quantity ELSE -inventory_items.quantity END) > 0")
          .order("inventory_items.name")

        render "api/v1/hangar_inventory_stock/index"
      end

      private def filtered_inventories
        scope = current_resource_owner.inventories
        return scope.hand_made unless ship_inventories_enabled?

        vehicle_id = params.dig(:q, :vehicle_id_eq)
        return scope if vehicle_id.blank?

        scope.where(vehicle_id: current_resource_owner.vehicles.where(id: vehicle_id))
      end
    end
  end
end
