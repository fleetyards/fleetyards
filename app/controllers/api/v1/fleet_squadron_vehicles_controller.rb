# frozen_string_literal: true

module Api
  module V1
    # What a squadron flies: the fleet's ship list narrowed to the squadron's
    # members.
    #
    # A subclass rather than a copy. Everything the fleet's ship list does --
    # the filters, the grouped-by-model branch, the pagination and the
    # partials -- is the same here, and the only difference is where the ships
    # come from. Rails resolves the views through the superclass's prefix, so
    # `api/v1/fleet_vehicles/*` renders both.
    class FleetSquadronVehiclesController < FleetVehiclesController
      include FleetSquadronScoped

      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron

      # An empty squadron flies nothing. `where(user_id: [])` is what says so;
      # dropping the condition for a blank list would hand back the whole fleet.
      private def vehicle_scope
        @fleet.vehicles.where(user_id: @fleet_squadron.member_user_ids)
      end
    end
  end
end
