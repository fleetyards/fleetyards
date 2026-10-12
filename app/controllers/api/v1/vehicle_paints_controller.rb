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

        # The paint the ship wears stays listed even once the catalogue hides it,
        # or the card would show no paint as applied.
        paints = @vehicle.model.paints
          .visible.active
          .or(@vehicle.model.paints.where(id: @vehicle.model_paint_id))
          .includes(:item_prices, *ModelPaint.attachment_preloads)
          .order(name: :asc)
          .to_a
        @owned_ids = HangarPledgeItems::OwnedPaints.new(current_resource_owner, @vehicle.model).paint_ids(paints).to_set
        @paints = paints.sort_by { |paint| @owned_ids.include?(paint.id) ? 0 : 1 }
      end

      private def set_vehicle
        @vehicle = current_resource_owner.vehicles.find_by_id_or_serial!(params[:vehicle_id])
      end
    end
  end
end
