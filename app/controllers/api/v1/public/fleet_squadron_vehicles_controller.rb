# frozen_string_literal: true

module Api
  module V1
    module Public
      # What a squadron flies, for a reader outside the fleet. The public ship
      # list narrowed to the squadron's members -- same filters, same partials,
      # same `Public::FleetPolicy#show?` gate.
      class FleetSquadronVehiclesController < FleetVehiclesController
        before_action :check_fleet_squadrons_feature
        before_action :set_fleet_squadron

        private def vehicle_scope
          @fleet.vehicles.where(user_id: @fleet_squadron.member_user_ids)
        end

        private def set_fleet_squadron
          @fleet_squadron = @fleet.fleet_squadrons.find_by!(slug: params[:fleet_squadron_slug])
        end

        private def check_fleet_squadrons_feature
          return if feature_enabled?("fleet_squadrons", @fleet)

          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
        end
      end
    end
  end
end
