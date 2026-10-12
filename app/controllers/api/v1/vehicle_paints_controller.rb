# frozen_string_literal: true

module Api
  module V1
    class VehiclePaintsController < ::Api::BaseController
      include VehicleOverviewFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) }
      before_action :check_vehicle_overview_feature

      before_action :set_vehicle

      def index
        authorize! @vehicle, to: :show?

        paints = @vehicle.model.paints.visible.active.order(name: :asc).to_a
        @owned_ids = HangarPledgeItems::OwnedPaints.new(current_resource_owner, @vehicle.model).paint_ids(paints).to_set
        @paints = paints.sort_by { |paint| @owned_ids.include?(paint.id) ? 0 : 1 }
      end

      private def set_vehicle
        vehicle_id = params[:vehicle_id]
        @vehicle = if vehicle_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-/i)
          current_resource_owner.vehicles.find(vehicle_id)
        else
          current_resource_owner.vehicles.find_by!(serial: vehicle_id.upcase)
        end
      end
    end
  end
end
