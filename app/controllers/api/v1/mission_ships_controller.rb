# frozen_string_literal: true

module Api
  module V1
    class MissionShipsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_mission
      before_action :set_team
      before_action :set_ship, only: %i[update destroy]

      def create
        @ship = @team.mission_ships.new(ship_params)
        @ship.position = next_position

        authorize! @ship, with: MissionShipPolicy, context: {mission: @mission}

        ActiveRecord::Base.transaction do
          @ship.save!
          materialize_position_slots(@ship, position_ids_param)
        end

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("mission_ships.create", errors: @ship.errors), status: :bad_request
      end

      def update
        authorize! @ship, with: MissionShipPolicy, context: {mission: @mission}

        if @ship.update(ship_params)
          render :show
        else
          render json: ValidationError.new("mission_ships.update", errors: @ship.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @ship, with: MissionShipPolicy, context: {mission: @mission}

        unless @ship.destroy
          render json: ValidationError.new("mission_ships.destroy", errors: @ship.errors), status: :bad_request
        end
      end

      def sort
        authorize! @mission, with: MissionShipPolicy, to: :sort?, context: {mission: @mission}

        sorting = params.permit(sorting: [])[:sorting] || []

        MissionShip.transaction do
          sorting.each_with_index do |id, index|
            @team.mission_ships.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def ship_params
        authorized(params, with: MissionShipPolicy)
      end

      private def position_ids_param
        Array(params[:position_ids]).map(&:to_s)
      end

      private def materialize_position_slots(ship, position_ids)
        return if position_ids.blank?
        return if ship.model_id.blank?

        positions = ship.model.model_positions.where(id: position_ids).order(:position)
        next_slot_position = -1
        positions.each do |mp|
          next_slot_position += 1
          ship.mission_slots.create!(
            title: mp.name,
            model_position_id: mp.id,
            position: next_slot_position
          )
        end
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_mission
        @mission = @fleet.missions.find_by!(slug: params[:mission_slug])
      end

      private def set_team
        @team = @mission.mission_teams.find(params[:mission_team_id])
      end

      private def set_ship
        @ship = @team.mission_ships.find(params[:id])
      end

      private def next_position
        (@team.mission_ships.maximum(:position) || -1) + 1
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
