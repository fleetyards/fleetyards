# frozen_string_literal: true

module Api
  module V1
    class FleetSquadronFlightsController < ::Api::BaseController
      include FleetSquadronScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy sort]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :check_fleet_squadron_flights_feature
      before_action :set_fleet_squadron
      before_action :check_squadron_flights_enabled
      before_action :set_flight, only: %i[show update destroy]

      def index
        authorize! with: FleetSquadronFlightPolicy, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        @flights = @fleet_squadron.fleet_squadron_flights.includes(mission_team: MissionTeams::Copier::TEAM_PRELOADS)
      end

      def show
        authorize! @flight, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}
      end

      def create
        @flight = @fleet_squadron.fleet_squadron_flights.new(flight_params)

        authorize! @flight, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        if @flight.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadron_flights.create", errors: @flight.errors), status: :bad_request
        end
      end

      def update
        authorize! @flight, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        if @flight.update(flight_params)
          render :show
        else
          render json: ValidationError.new("fleet_squadron_flights.update", errors: @flight.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @flight, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        return head :no_content if @flight.destroy

        render json: ValidationError.new("fleet_squadron_flights.destroy", errors: @flight.errors), status: :bad_request
      end

      def sort
        authorize! with: FleetSquadronFlightPolicy, to: :sort?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        sorting = params.permit(sorting: [])[:sorting] || []

        FleetSquadronFlight.transaction do
          sorting.each_with_index do |id, index|
            @fleet_squadron.fleet_squadron_flights.where(id:).update_all(position: index)
          end
        end

        head :no_content
      end

      private def flight_params
        params.transform_keys(&:underscore).permit(:name, :description)
      end

      private def set_flight
        @flight = @fleet_squadron.fleet_squadron_flights
          .includes(mission_team: MissionTeams::Copier::TEAM_PRELOADS)
          .find(params[:id])
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
