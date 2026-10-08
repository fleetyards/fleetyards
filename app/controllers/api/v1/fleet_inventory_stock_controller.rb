# frozen_string_literal: true

module Api
  module V1
    class FleetInventoryStockController < ::Api::BaseController
      include FleetInventoryScoped
      include FleetSubscriptionConcern
      include InventoryScoped::StockActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :set_fleet
      before_action :check_fleet_logistics_feature
      before_action -> { require_fleet_subscription(:logistics) }
      before_action :inventory
      before_action :set_stock_item, only: %i[show update destroy]

      private def inventory
        @inventory ||= visible_fleet_inventories.find_by!(slug: params[:fleet_inventory_slug])
      end

      # Stock rules are granted per fleet role, not per inventory, so they are
      # asked of the fleet rather than of the inventory record.
      private def authorize_stock!(rule)
        authorize! with: FleetInventoryItemPolicy, to: rule, context: {fleet: @fleet}
      end

      private def validation_error_scope
        "fleet_inventory_items"
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def check_fleet_logistics_feature
        return if feature_enabled?("fleet_logistics", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
