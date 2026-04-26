# frozen_string_literal: true

module Api
  module V1
    class FleetInventoryItemsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_inventory_items) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :set_fleet
      before_action :set_fleet_inventory
      before_action :set_fleet_inventory_item, only: %i[update destroy]

      def index
        authorize! with: FleetInventoryItemPolicy, context: {fleet: @fleet}

        scope = @fleet_inventory.fleet_inventory_items

        query_params = params.fetch(:q, {}).permit(:name_cont, :category_eq, :quality_gteq, :quality_lteq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetInventoryItem, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @fleet_inventory_items = result_with_pagination(result, per_page(FleetInventoryItem))
      end

      def create
        @fleet_inventory_item = @fleet_inventory.fleet_inventory_items.new(fleet_inventory_item_params)
        @fleet_inventory_item.added_by = current_resource_owner.id

        authorize! @fleet_inventory_item, context: {fleet: @fleet}

        if @fleet_inventory_item.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_inventory_items.create", errors: @fleet_inventory_item.errors), status: :bad_request
        end
      end

      def update
        authorize! @fleet_inventory_item, context: {fleet: @fleet}

        if @fleet_inventory_item.update(fleet_inventory_item_params)
          render :show
        else
          render json: ValidationError.new("fleet_inventory_items.update", errors: @fleet_inventory_item.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_inventory_item, context: {fleet: @fleet}

        unless @fleet_inventory_item.destroy
          render json: ValidationError.new("fleet_inventory_items.destroy", errors: @fleet_inventory_item.errors), status: :bad_request
        end
      end

      def import
        authorize! with: FleetInventoryItemPolicy, context: {fleet: @fleet}, to: :create?

        file = params.require(:file)

        importer = FleetInventoryItemCsvImporter.new(@fleet_inventory, file, current_resource_owner)
        result = importer.call

        render json: result, status: :ok
      end

      private def fleet_inventory_item_params
        authorized(params, with: FleetInventoryItemPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_inventory
        @fleet_inventory = @fleet.fleet_inventories.find_by!(slug: params[:fleet_inventory_slug])
      end

      private def set_fleet_inventory_item
        @fleet_inventory_item = @fleet_inventory.fleet_inventory_items.find(params[:id])
      end
    end
  end
end
