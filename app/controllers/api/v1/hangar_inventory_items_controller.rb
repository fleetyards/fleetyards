# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryItemsController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      after_action -> { pagination_header(:hangar_inventory_items) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy import]

      before_action :check_hangar_inventories_feature
      before_action :set_hangar_inventory
      before_action :set_hangar_inventory_item, only: %i[update destroy]

      def index
        authorize!

        scope = @hangar_inventory.hangar_inventory_items

        query_params = params.fetch(:q, {}).permit(:name_cont, :category_eq, :quality_gteq, :quality_lteq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(HangarInventoryItem, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @hangar_inventory_items = result_with_pagination(result, per_page(HangarInventoryItem))
      end

      def create
        @hangar_inventory_item = @hangar_inventory.hangar_inventory_items.new(hangar_inventory_item_params)

        authorize! @hangar_inventory_item

        if @hangar_inventory_item.save
          render :show, status: :created
        else
          render json: ValidationError.new("hangar_inventory_items.create", errors: @hangar_inventory_item.errors), status: :bad_request
        end
      end

      def update
        authorize! @hangar_inventory_item

        if @hangar_inventory_item.update(hangar_inventory_item_params)
          render :show
        else
          render json: ValidationError.new("hangar_inventory_items.update", errors: @hangar_inventory_item.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @hangar_inventory_item

        unless @hangar_inventory_item.destroy
          render json: ValidationError.new("hangar_inventory_items.destroy", errors: @hangar_inventory_item.errors), status: :bad_request
        end
      end

      def import
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :update?

        file = params.require(:file)

        importer = InventoryItemCsvImporter.new(@hangar_inventory, file, current_resource_owner)
        result = importer.call

        render json: result, status: :ok
      end

      private def hangar_inventory_item_params
        authorized(params, with: HangarInventoryItemPolicy)
      end

      private def set_hangar_inventory
        @hangar_inventory = current_resource_owner.hangar_inventories.find_by!(slug: params[:hangar_inventory_slug])
      end

      private def set_hangar_inventory_item
        @hangar_inventory_item = @hangar_inventory.hangar_inventory_items.find(params[:id])
      end
    end
  end
end
