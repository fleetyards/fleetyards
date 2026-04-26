# frozen_string_literal: true

module Api
  module V1
    class FleetAllInventoryStockController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      before_action :check_fleet_logistics_feature
      before_action :set_fleet

      def index
        authorize! with: FleetInventoryItemPolicy, context: {fleet: @fleet}

        inventory_ids = @fleet.fleet_inventories.pluck(:id)

        @stock = FleetInventoryItem
          .where(fleet_inventory_id: inventory_ids)
          .joins(:fleet_inventory)
          .select(
            "fleet_inventory_items.name",
            "fleet_inventory_items.category",
            "fleet_inventory_items.unit",
            "MIN(fleet_inventory_items.quality) AS quality_min",
            "MAX(fleet_inventory_items.quality) AS quality_max",
            "fleet_inventories.name AS inventory_name",
            "fleet_inventories.slug AS inventory_slug",
            "SUM(CASE WHEN fleet_inventory_items.entry_type = 0 THEN fleet_inventory_items.quantity ELSE -fleet_inventory_items.quantity END) AS net_quantity"
          )
          .group(
            "fleet_inventory_items.name",
            "fleet_inventory_items.category",
            "fleet_inventory_items.unit",
            "fleet_inventories.name",
            "fleet_inventories.slug"
          )
          .having("SUM(CASE WHEN fleet_inventory_items.entry_type = 0 THEN fleet_inventory_items.quantity ELSE -fleet_inventory_items.quantity END) > 0")
          .order("fleet_inventory_items.name")

        render "api/v1/fleet_inventory_stock/index"
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def check_fleet_logistics_feature
        return if feature_enabled?("fleet_logistics")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
