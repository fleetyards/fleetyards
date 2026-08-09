# frozen_string_literal: true

module Api
  module V1
    class HangarAllInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      before_action :check_hangar_inventories_feature

      def index
        authorize! with: HangarInventoryItemPolicy, to: :index?

        inventory_ids = current_resource_owner.hangar_inventories.pluck(:id)

        @stock = HangarInventoryItem
          .where(hangar_inventory_id: inventory_ids)
          .joins(:hangar_inventory)
          .select(
            "hangar_inventory_items.name",
            "hangar_inventory_items.category",
            "hangar_inventory_items.unit",
            "MIN(hangar_inventory_items.quality) AS quality_min",
            "MAX(hangar_inventory_items.quality) AS quality_max",
            "hangar_inventories.name AS inventory_name",
            "hangar_inventories.slug AS inventory_slug",
            "SUM(CASE WHEN hangar_inventory_items.entry_type = 0 THEN hangar_inventory_items.quantity ELSE -hangar_inventory_items.quantity END) AS net_quantity"
          )
          .group(
            "hangar_inventory_items.name",
            "hangar_inventory_items.category",
            "hangar_inventory_items.unit",
            "hangar_inventories.name",
            "hangar_inventories.slug"
          )
          .having("SUM(CASE WHEN hangar_inventory_items.entry_type = 0 THEN hangar_inventory_items.quantity ELSE -hangar_inventory_items.quantity END) > 0")
          .order("hangar_inventory_items.name")

        render "api/v1/hangar_inventory_stock/index"
      end
    end
  end
end
