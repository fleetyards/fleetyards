# frozen_string_literal: true

module Api
  module V1
    # A squadron's numbers: the fleet's own figures, counted over the squadron's
    # members and their ships. See `FleetSquadronVehiclesController` for why
    # this subclasses rather than restates.
    class FleetSquadronStatsController < FleetStatsController
      include FleetSquadronScoped

      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron

      private def vehicle_scope
        @fleet.vehicles.where(user_id: @fleet_squadron.member_user_ids)
      end

      private def membership_scope
        @fleet_squadron.accepted_fleet_memberships
      end
    end
  end
end
