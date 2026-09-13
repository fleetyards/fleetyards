# frozen_string_literal: true

module Api
  module V1
    # Transfers a fleet sends from, or has to answer for.
    #
    # The fleet in the path is who this acts *for*; whether the signed-in user
    # may act for it is `Inventories::TransferAuthorizer`'s question, asked
    # through `InventoryTransferPolicy` like everywhere else.
    class FleetInventoryTransfersController < ::Api::BaseController
      include InventoryTransferActions

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create accept decline cancel report]

      before_action :check_inventory_transfers_feature
      before_action :set_fleet
      before_action :check_fleet_logistics_feature
      before_action :set_inventory_transfer, only: %i[show accept decline cancel report]

      private def acting_party
        @fleet
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def check_fleet_logistics_feature
        return if feature_enabled?("fleet_logistics", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
