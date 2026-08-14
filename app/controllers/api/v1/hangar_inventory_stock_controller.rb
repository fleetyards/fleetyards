# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include InventoryScoped::StockActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[update destroy]

      before_action :check_hangar_inventories_feature
      before_action :set_stock_item, only: %i[show update destroy]

      private def inventory
        @inventory ||= current_resource_owner.inventories.addressable_by_slug.find_by!(slug: params[:hangar_inventory_slug])
      end

      private def inventory_policy
        HangarInventoryPolicy
      end

      # The stock endpoints render entry-level validation failures, so they share
      # the item scope rather than carrying one of their own.
      private def validation_error_scope
        "hangar_inventory_items"
      end
    end
  end
end
