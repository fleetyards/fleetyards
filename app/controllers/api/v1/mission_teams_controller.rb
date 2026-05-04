# frozen_string_literal: true

module Api
  module V1
    class MissionTeamsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_mission
      before_action :set_team, only: %i[update destroy]

      def create
        @team = @mission.mission_teams.new(team_params)
        @team.position = next_position

        authorize! @team, with: MissionTeamPolicy, context: {mission: @mission}

        if @team.save
          render :show, status: :created
        else
          render json: ValidationError.new("mission_teams.create", errors: @team.errors), status: :bad_request
        end
      end

      def update
        authorize! @team, with: MissionTeamPolicy, context: {mission: @mission}

        if @team.update(team_params)
          render :show
        else
          render json: ValidationError.new("mission_teams.update", errors: @team.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @team, with: MissionTeamPolicy, context: {mission: @mission}

        unless @team.destroy
          render json: ValidationError.new("mission_teams.destroy", errors: @team.errors), status: :bad_request
        end
      end

      def sort
        authorize! @mission, with: MissionTeamPolicy, to: :sort?, context: {mission: @mission}

        sorting = params.permit(sorting: [])[:sorting] || []

        MissionTeam.transaction do
          sorting.each_with_index do |id, index|
            @mission.mission_teams.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def team_params
        authorized(params, with: MissionTeamPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_mission
        @mission = @fleet.missions.find_by!(slug: params[:mission_slug])
      end

      private def set_team
        @team = @mission.mission_teams.find(params[:id])
      end

      private def next_position
        (@mission.mission_teams.maximum(:position) || -1) + 1
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
