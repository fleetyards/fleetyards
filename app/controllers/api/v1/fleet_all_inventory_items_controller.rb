# frozen_string_literal: true

module Api
  module V1
    class FleetAllInventoryItemsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_inventory_items) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?

      before_action :check_fleet_logistics_feature
      before_action :set_fleet

      def index
        authorize! with: FleetInventoryItemPolicy, context: {fleet: @fleet}

        scope = FleetInventoryItem
          .joins(:fleet_inventory)
          .where(fleet_inventories: {fleet_id: @fleet.id})
          .includes(:fleet_inventory)

        query_params = params.fetch(:q, {}).permit(:name_cont, :category_eq, :quality_gteq, :quality_lteq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(FleetInventoryItem, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @fleet_inventory_items = result_with_pagination(result, per_page(FleetInventoryItem))

        render "api/v1/fleet_inventory_items/index"
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
