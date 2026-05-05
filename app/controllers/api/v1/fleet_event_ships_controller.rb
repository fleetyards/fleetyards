# frozen_string_literal: true

module Api
  module V1
    class FleetEventShipsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_event
      before_action :set_team
      before_action :set_ship, only: %i[update destroy expand_from_model]

      def create
        @ship = @team.fleet_event_ships.new(ship_params)
        @ship.position = next_position

        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :create?

        ActiveRecord::Base.transaction do
          @ship.save!
          materialize_position_slots(@ship, position_ids_param)
        end

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("fleet_event_ships.create", errors: @ship.errors), status: :bad_request
      end

      def update
        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :update?

        if @ship.update(ship_params)
          render :show
        else
          render json: ValidationError.new("fleet_event_ships.update", errors: @ship.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :destroy?

        unless @ship.destroy
          render json: ValidationError.new("fleet_event_ships.destroy", errors: @ship.errors), status: :bad_request
        end
      end

      # Adds extra slots to this ship for any model_positions of the given
      # model that aren't already represented as slots — useful when a member
      # signs up with a specific vehicle and we want to materialize the
      # remaining seats (gunner, copilot, …) so other members can join.
      def expand_from_model
        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :update?

        model = Model.find(params[:model_id])

        existing_position_ids = @ship.fleet_event_slots.where.not(model_position_id: nil).pluck(:model_position_id)
        positions = model.model_positions.where.not(id: existing_position_ids)

        if (requested = position_ids_param).present?
          positions = positions.where(id: requested)
        end

        positions = positions.order(:position)

        if positions.empty?
          render json: {code: "no_new_positions", message: "No additional positions to add"}, status: :unprocessable_entity
          return
        end

        next_slot_position = @ship.fleet_event_slots.maximum(:position) || -1

        ActiveRecord::Base.transaction do
          positions.each do |mp|
            next_slot_position += 1
            @ship.fleet_event_slots.create!(
              title: mp.name,
              model_position_id: mp.id,
              position: next_slot_position
            )
          end
        end

        render :show
      end

      def sort
        authorize! @event, with: FleetEventShipPolicy, to: :sort?, context: {fleet_event: @event}

        sorting = params.permit(sorting: [])[:sorting] || []

        FleetEventShip.transaction do
          sorting.each_with_index do |id, index|
            @team.fleet_event_ships.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def ship_params
        authorized(params, with: FleetEventShipPolicy)
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
          ship.fleet_event_slots.create!(
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

      private def set_event
        @event = @fleet.fleet_events.find_by!(slug: params[:fleet_event_slug])
      end

      private def set_team
        @team = @event.fleet_event_teams.find(params[:fleet_event_team_id])
      end

      private def set_ship
        @ship = @team.fleet_event_ships.find(params[:id])
      end

      private def next_position
        (@team.fleet_event_ships.maximum(:position) || -1) + 1
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
