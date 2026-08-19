# frozen_string_literal: true

module Api
  module V1
    class FleetEventShipsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :set_fleet
      before_action :check_fleet_mission_builder_feature
      before_action :set_event
      before_action :set_team
      before_action :set_ship, only: %i[update destroy expand_from_model]

      def create
        @ship = @team.fleet_event_ships.new(ship_params)
        @ship.position = next_position
        # Built rather than written: model_or_filter_required runs on save and a
        # spot that names only a list has nothing else to satisfy it, so the rows
        # have to exist in memory by then.
        build_allowed_models(@ship, allowed_model_ids_param)

        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :create?

        ActiveRecord::Base.transaction do
          @ship.save!
          materialize_position_slots(@ship, position_ids_param)
        end

        # The associations were read during validation, when the rows were still
        # in memory, so the response would otherwise serialise that stale view.
        @ship.reload

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("fleet_event_ships.create", errors: @ship.errors), status: :bad_request
      end

      def update
        authorize! @ship, with: FleetEventShipPolicy, context: {fleet_event: @event}, to: :update?

        ActiveRecord::Base.transaction do
          sync_allowed_models!(@ship, allowed_model_ids_param)
          @ship.update!(ship_params)
        end

        render :show
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("fleet_event_ships.update", errors: @ship.errors), status: :bad_request
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
        authorized(params, with: FleetEventShipPolicy).except(:allowed_model_ids)
      end

      # nil when the client did not mention the list at all, which leaves it
      # alone; [] is a client clearing it.
      private def allowed_model_ids_param
        permitted = authorized(params, with: FleetEventShipPolicy)
        return unless permitted.key?(:allowed_model_ids)

        Array(permitted[:allowed_model_ids]).map(&:to_s).compact_blank.uniq
      end

      private def build_allowed_models(ship, ids)
        return if ids.blank?

        ids.each_with_index do |model_id, index|
          ship.fleet_event_ship_models.build(model_id: model_id, position: index)
        end
      end

      # A supplied list is the whole answer to "which ships fit here", so rows
      # that are not in it go. Reset afterwards so the validation on update reads
      # the list as it now stands rather than as it was loaded.
      private def sync_allowed_models!(ship, ids)
        return if ids.nil?

        ship.fleet_event_ship_models.where.not(model_id: ids).destroy_all
        ids.each_with_index do |model_id, index|
          record = ship.fleet_event_ship_models.find_or_initialize_by(model_id: model_id)
          record.position = index
          record.save! if record.changed?
        end
        ship.fleet_event_ship_models.reset
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

      private def check_fleet_mission_builder_feature
        return if feature_enabled?("fleet_mission_builder", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
