# frozen_string_literal: true

module Api
  module V1
    class HangarInventoriesController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      after_action -> { pagination_header(:hangar_inventories) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :check_hangar_inventories_feature
      before_action :set_hangar_inventory, only: %i[show update destroy]

      def index
        authorize!

        scope = current_resource_owner.hangar_inventories

        query_params = params.fetch(:q, {}).permit(:name_cont, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(HangarInventory, query_params["sorts"])

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @hangar_inventories = result_with_pagination(result, per_page(HangarInventory))
      end

      def show
        authorize! @hangar_inventory
      end

      def create
        @hangar_inventory = current_resource_owner.hangar_inventories.new(hangar_inventory_params)

        authorize! @hangar_inventory

        if @hangar_inventory.save
          render :show, status: :created
        else
          render json: ValidationError.new("hangar_inventories.create", errors: @hangar_inventory.errors), status: :bad_request
        end
      end

      def update
        authorize! @hangar_inventory

        if @hangar_inventory.update(hangar_inventory_params)
          render :show
        else
          render json: ValidationError.new("hangar_inventories.update", errors: @hangar_inventory.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @hangar_inventory

        unless @hangar_inventory.destroy
          render json: ValidationError.new("hangar_inventories.destroy", errors: @hangar_inventory.errors), status: :bad_request
        end
      end

      private def hangar_inventory_params
        authorized(params, with: HangarInventoryPolicy)
      end

      private def set_hangar_inventory
        @hangar_inventory = current_resource_owner.hangar_inventories.find_by!(slug: params[:slug])
      end
    end
  end
end
