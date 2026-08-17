# frozen_string_literal: true

module Api
  module V1
    class FleetInventoryStockController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :set_fleet
      before_action :check_fleet_logistics_feature
      before_action :set_fleet_inventory
      before_action :set_stock_item, only: %i[show update destroy]

      def index
        authorize! with: FleetInventoryItemPolicy, to: :index?, context: {fleet: @fleet}

        @stock = @fleet_inventory.current_stock
      end

      def show
        authorize! with: FleetInventoryItemPolicy, to: :index?, context: {fleet: @fleet}
      end

      def update
        authorize! with: FleetInventoryItemPolicy, to: :update?, context: {fleet: @fleet}

        change = @fleet_inventory.update_stock_item(@stock_item, stock_item_params)

        unless change.valid?
          return render json: ValidationError.new("fleet_inventory_items.update", errors: change.errors),
            status: :bad_request
        end

        @stock_item = @fleet_inventory.stock_item(
          InventoryStockItem.slug_for(name: change.name, category: change.category, unit: change.unit)
        )

        render :show
      end

      def destroy
        authorize! with: FleetInventoryItemPolicy, to: :destroy?, context: {fleet: @fleet}

        @fleet_inventory.destroy_stock_item(@stock_item)
      end

      private def stock_item_params
        params.permit(:name, :category, :unit).to_h.symbolize_keys
      end

      private def set_stock_item
        @stock_item = @fleet_inventory.stock_item(params[:slug])

        not_found if @stock_item.blank?
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_inventory
        @fleet_inventory = @fleet.fleet_inventories.find_by!(slug: params[:fleet_inventory_slug])
      end

      private def check_fleet_logistics_feature
        return if feature_enabled?("fleet_logistics", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
