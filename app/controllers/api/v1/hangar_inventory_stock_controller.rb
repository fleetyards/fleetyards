# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :check_hangar_inventories_feature
      before_action :set_hangar_inventory
      before_action :set_stock_item, only: %i[show update destroy]

      def index
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :show?

        @stock = @hangar_inventory.current_stock
      end

      def show
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :show?
      end

      def update
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :update?

        change = @hangar_inventory.update_stock_item(@stock_item, stock_item_params)

        unless change.valid?
          return render json: ValidationError.new("hangar_inventory_items.update", errors: change.errors),
            status: :bad_request
        end

        @stock_item = @hangar_inventory.stock_item(
          InventoryStockItem.slug_for(name: change.name, category: change.category, unit: change.unit)
        )

        render :show
      end

      def destroy
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :update?

        @hangar_inventory.destroy_stock_item(@stock_item)
      end

      private def stock_item_params
        params.permit(:name, :category, :unit).to_h.symbolize_keys
      end

      private def set_stock_item
        @stock_item = @hangar_inventory.stock_item(params[:slug])

        not_found if @stock_item.blank?
      end

      private def set_hangar_inventory
        @hangar_inventory = current_resource_owner.inventories.find_by!(slug: params[:hangar_inventory_slug])
      end
    end
  end
end
