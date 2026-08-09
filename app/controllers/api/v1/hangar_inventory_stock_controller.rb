# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryStockController < ::Api::BaseController
      include HangarInventoriesFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      before_action :check_hangar_inventories_feature
      before_action :set_hangar_inventory

      def index
        authorize! @hangar_inventory, with: HangarInventoryPolicy, to: :show?

        @stock = @hangar_inventory.current_stock
      end

      private def set_hangar_inventory
        @hangar_inventory = current_resource_owner.hangar_inventories.find_by!(slug: params[:hangar_inventory_slug])
      end
    end
  end
end
