# frozen_string_literal: true

module Api
  module V1
    class HangarInventoryItemsController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include InventoryScoped::ItemActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy import]

      before_action :check_hangar_inventories_feature
      before_action :set_inventory_item, only: %i[update destroy]

      private def inventory
        @inventory ||= current_resource_owner.inventories.addressable_by_slug.find_by!(slug: params[:hangar_inventory_slug])
      end

      private def inventory_policy
        HangarInventoryPolicy
      end

      private def inventory_item_policy
        HangarInventoryItemPolicy
      end

      private def validation_error_scope
        "hangar_inventory_items"
      end
    end
  end
end
