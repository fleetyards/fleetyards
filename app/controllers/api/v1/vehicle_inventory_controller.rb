# frozen_string_literal: true

module Api
  module V1
    class VehicleInventoryController < ::Api::BaseController
      include HangarInventoriesFeatureConcern
      include VehicleInventoryScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[destroy]

      before_action :check_hangar_inventories_feature
      before_action :set_vehicle

      def show
        authorize! inventory, with: inventory_policy, to: :show?
      end

      # Clearing a ship's cargo. Dropping the row is safe because the next
      # deposit provisions it again.
      def destroy
        authorize! inventory, with: inventory_policy, to: :destroy?

        return if inventory.new_record?
        return if inventory.destroy

        render json: ValidationError.new("#{validation_error_scope}.destroy", errors: inventory.errors),
          status: :bad_request
      end

      private def validation_error_scope
        "vehicle_inventory"
      end
    end
  end
end
