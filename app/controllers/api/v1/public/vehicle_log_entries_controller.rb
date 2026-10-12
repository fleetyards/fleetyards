# frozen_string_literal: true

module Api
  module V1
    module Public
      class VehicleLogEntriesController < ::Api::PublicBaseController
        include HangarShareTokenConcern

        before_action :set_user
        before_action :check_owner_feature
        before_action :set_vehicle

        def index
          @log_entries = @vehicle.public_log_entries.chronological
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

          authorize! @user, to: :show?, with: ::Public::UserPolicy
        end

        # The owner shared the entries, so it is the owner's flag that decides,
        # not the visitor's -- who may well be signed out.
        private def check_owner_feature
          return if Flipper.enabled?(:vehicle_overview, @user)

          render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
        end

        # The same vehicles the public hangar lists, so an entry is only ever
        # readable next to a ship its owner already shows.
        private def set_vehicle
          @vehicle = @user.vehicles.purchased.public.find(params[:vehicle_id])
        end
      end
    end
  end
end
