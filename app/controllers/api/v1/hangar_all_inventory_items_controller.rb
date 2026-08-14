# frozen_string_literal: true

module Api
  module V1
    class HangarAllInventoryItemsController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      after_action -> { pagination_header(:inventory_items) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      before_action :check_hangar_inventories_feature

      def index
        authorize! with: HangarInventoryItemPolicy, to: :index?

        scope = InventoryItem
          .joins(:inventory)
          .where(inventories: {holder: current_resource_owner})
          .includes(:inventory)

        query_params = params.fetch(:q, {}).permit(:name_cont, :category_eq, :quality_gteq, :quality_lteq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(InventoryItem, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @inventory_items = result_with_pagination(result, per_page(InventoryItem))

        render "api/v1/hangar_inventory_items/index"
      end
    end
  end
end
