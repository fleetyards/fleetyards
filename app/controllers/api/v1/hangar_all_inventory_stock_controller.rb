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
          .joins(:inventory, :inventory_position)
          .joins("LEFT JOIN vehicles ON vehicles.id = inventories.vehicle_id")
          .joins("LEFT JOIN models ON models.id = vehicles.model_id")
          .select(
            "inventory_positions.id AS inventory_position_id",
            "inventory_positions.name",
            "inventory_positions.category",
            "inventory_positions.unit",
            "inventory_positions.slug",
            "MIN(inventory_items.quality) AS quality_min",
            "MAX(inventory_items.quality) AS quality_max",
            # A position groups entries by name, category and unit, so its
            # rows need not agree on which catalogue record they point at --
            # and the link is optional, so some may point at none. Answered
            # only where the ones that do answer agree, since a position
            # holding two different items is not either of them.
            "CASE WHEN COUNT(DISTINCT inventory_items.item_id) = 1 " \
              "THEN MIN(inventory_items.item_type) END AS item_type",
            "CASE WHEN COUNT(DISTINCT inventory_items.item_id) = 1 " \
              "THEN MIN(inventory_items.item_id::text) END AS item_id",
            "inventories.name AS inventory_name",
            "inventories.slug AS inventory_slug",
            # An inventory either stands on its own or belongs to a ship, and
            # "on your Avenger" places the stock in a way its inventory's name
            # need not. Mirrors `Vehicle#display_name`.
            "NULLIF(COALESCE(NULLIF(vehicles.name, ''), models.name), '') AS vehicle_name",
            "SUM(CASE WHEN inventory_items.entry_type = 0 THEN inventory_items.quantity ELSE -inventory_items.quantity END) AS net_quantity"
          )
          .group(
            "inventory_positions.id",
            "inventory_positions.name",
            "inventory_positions.category",
            "inventory_positions.unit",
            "inventory_positions.slug",
            "inventories.name",
            "inventories.slug",
            "vehicles.name",
            "models.name"
          )
          .having("SUM(CASE WHEN inventory_items.entry_type = 0 THEN inventory_items.quantity ELSE -inventory_items.quantity END) > 0")
          .order("inventory_positions.name")

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
