# frozen_string_literal: true

module Api
  module V1
    # Transfers a user sends from, or has to answer for, themselves.
    class HangarInventoryTransfersController < ::Api::BaseController
      include InventoryTransferActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[create accept decline cancel report]

      before_action :check_inventory_transfers_feature
      before_action :set_inventory_transfer, only: %i[show accept decline cancel report]

      private def acting_party
        current_resource_owner
      end
    end
  end
end
