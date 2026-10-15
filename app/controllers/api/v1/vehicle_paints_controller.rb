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

        # A paint the ship owns stays listed even once the catalogue hides it,
        # or the card would lose it.
        owned_ids = @vehicle.model_paint_ids
        picture_id = @vehicle.picture_id if @vehicle.picture_type == "ModelPaint"
        kept_ids = owned_ids | [picture_id].compact
        paints = @vehicle.model.paints
          .visible.active
          .or(@vehicle.model.paints.where(id: kept_ids))
          .includes(:item_prices, *ModelPaint.attachment_preloads)
          .order(name: :asc)
          .to_a
        @owned_ids = owned_ids.to_set
        @pledged_ids = HangarPledgeItems::OwnedPaints.new(current_resource_owner).paint_ids(paints).to_set
        @paints = paints.sort_by do |paint|
          if @owned_ids.include?(paint.id) then 0
          elsif @pledged_ids.include?(paint.id) then 1
          else 2
          end
        end
      end

      private def set_vehicle
        @vehicle = current_resource_owner.vehicles.find_by_id_or_serial!(params[:vehicle_id])
      end
    end
  end
end
