# frozen_string_literal: true

module Api
  module V1
    # A flight's ships, edited with the template editor's actions.
    class FleetSquadronFlightShipsController < MissionShipsController
      include FleetSquadronFlightScoped

      skip_before_action :set_fleet
      skip_before_action :set_mission
      skip_before_action :set_team
      skip_before_action :set_ship

      before_action :load_flight!
      before_action :check_flight_squadrons_feature
      before_action :set_team
      before_action :set_ship, only: %i[update destroy duplicate]

      private def set_team
        @team = @flight.team
      end

      private def authorize_ship!(_record, to: nil)
        authorize_flight!
      end
    end
  end
end
