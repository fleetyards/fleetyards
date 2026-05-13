# frozen_string_literal: true

module Api
  module V1
    class FleetEventTeamsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_event
      before_action :set_team, only: %i[update destroy]

      def create
        @team = @event.fleet_event_teams.new(team_params)
        @team.position = next_position

        authorize! @team, with: FleetEventTeamPolicy, context: {fleet_event: @event}, to: :create?

        if @team.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_event_teams.create", errors: @team.errors), status: :bad_request
        end
      end

      def update
        authorize! @team, with: FleetEventTeamPolicy, context: {fleet_event: @event}, to: :update?

        if @team.update(team_params)
          render :show
        else
          render json: ValidationError.new("fleet_event_teams.update", errors: @team.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @team, with: FleetEventTeamPolicy, context: {fleet_event: @event}, to: :destroy?

        unless @team.destroy
          render json: ValidationError.new("fleet_event_teams.destroy", errors: @team.errors), status: :bad_request
        end
      end

      def sort
        authorize! @event, with: FleetEventTeamPolicy, to: :sort?, context: {fleet_event: @event}

        sorting = params.permit(sorting: [])[:sorting] || []

        FleetEventTeam.transaction do
          sorting.each_with_index do |id, index|
            @event.fleet_event_teams.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def team_params
        authorized(params, with: FleetEventTeamPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_event
        @event = @fleet.fleet_events.find_by!(slug: params[:fleet_event_slug])
      end

      private def set_team
        @team = @event.fleet_event_teams.find(params[:id])
      end

      private def next_position
        (@event.fleet_event_teams.maximum(:position) || -1) + 1
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
