# frozen_string_literal: true

module Api
  module V1
    module Public
      class VehicleLogEntriesController < ::Api::PublicBaseController
        include HangarShareTokenConcern
        include VehicleOverviewFeatureConcern

        before_action :check_vehicle_overview_feature
        before_action :set_vehicle

        def index
          @log_entries = @vehicle.public_log_entries.chronological
        end

        # The same vehicles the public hangar lists, so an entry is only ever
        # readable next to a ship its owner already shows.
        private def set_vehicle
          user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! user, to: :show?, with: ::Public::UserPolicy

          @vehicle = user.vehicles.purchased.public.find(params[:vehicle_id])
        end
      end
    end
  end
end
