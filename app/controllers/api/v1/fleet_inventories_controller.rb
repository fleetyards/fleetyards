# frozen_string_literal: true

module Api
  module V1
    class FleetInventoriesController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_inventories) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :check_fleet_logistics_feature
      before_action :set_fleet
      before_action :set_fleet_inventory, only: %i[show update destroy]

      def index
        authorize! with: FleetInventoryPolicy, context: {fleet: @fleet}

        scope = @fleet.fleet_inventories

        query_params = params.fetch(:q, {}).permit(:name_cont, :visibility_eq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetInventory, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @fleet_inventories = result_with_pagination(result, per_page(FleetInventory))
      end

      def show
        authorize! @fleet_inventory
      end

      def create
        @fleet_inventory = @fleet.fleet_inventories.new(fleet_inventory_params)

        authorize! @fleet_inventory

        if @fleet_inventory.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_inventories.create", errors: @fleet_inventory.errors), status: :bad_request
        end
      end

      def update
        authorize! @fleet_inventory

        if @fleet_inventory.update(fleet_inventory_params)
          render :show
        else
          render json: ValidationError.new("fleet_inventories.update", errors: @fleet_inventory.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_inventory

        unless @fleet_inventory.destroy
          render json: ValidationError.new("fleet_inventories.destroy", errors: @fleet_inventory.errors), status: :bad_request
        end
      end

      private def fleet_inventory_params
        authorized(params, with: FleetInventoryPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_fleet_inventory
        @fleet_inventory = @fleet.fleet_inventories.find_by!(slug: params[:slug])
      end

      private def check_fleet_logistics_feature
        return if feature_enabled?("fleet_logistics")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
