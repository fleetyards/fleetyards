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
        only: %i[update destroy handover]

      before_action :set_fleet
      before_action :check_fleet_logistics_feature
      before_action -> { require_fleet_subscription(:logistics) }
      # Resolved before any rule runs, so an unknown or hidden inventory answers
      # 404 rather than a 403 that would confirm it exists.
      before_action :inventory
      before_action :set_stock_item, only: %i[show update destroy handover]
      before_action :set_holder_balances, only: %i[index]

      def handover
        authorize_stock!(:create?)

        handover = ::Inventories::Handover.new(inventory:, stock_item: @stock_item, actor: current_resource_owner,
          **handover_params)

        unless handover.call
          return render json: ValidationError.new("fleet_inventory_items.handover", errors: handover.errors),
            status: :bad_request
        end

        @stock_item = inventory.stock_item(@stock_item.slug)

        render :show
      end

      private def handover_params
        params.permit(:quantity, :from_holder_id, :to_holder_id, :quality, :crafted_blueprint_id,
          crafted_qualities: {}).to_h.symbolize_keys
      end

      private def inventory
        @inventory ||= visible_fleet_inventories.find_by!(slug: params[:fleet_inventory_slug])
      end

      # Stock rules are granted per fleet role, not per inventory, so they are
      # asked of the fleet rather than of the inventory record.
      private def authorize_stock!(rule)
        authorize! with: FleetInventoryItemPolicy, to: rule, context: {fleet: @fleet}
      end

      # The caller's own share only, so a member can hold the list against what
      # they are carrying in game.
      private def stock_filters
        held_by_me? ? {holder_id: current_resource_owner.id} : {}
      end

      private def held_by_me?
        ActiveModel::Type::Boolean.new.cast(params[:heldByMe] || params[:held_by_me]) || false
      end

      private def set_holder_balances
        @holder_balances = InventoryHolderBalances.new(inventory.fleet_inventory_items, **stock_filters)
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
