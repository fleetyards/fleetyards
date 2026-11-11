# frozen_string_literal: true

module Api
  module V1
    class MissionSlotsController < ::Api::BaseController
      include FleetSubscriptionConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :set_slottable, only: %i[create]
      before_action :set_slot, only: %i[update destroy]
      before_action :check_fleet_mission_builder_feature
      before_action :require_events_subscription

      def create
        @slot = @slottable.mission_slots.new(slot_attrs)
        @slot.position = next_position

        authorize_slot!(@slot, @slottable)

        if @slot.save
          render :show, status: :created
        else
          render json: ValidationError.new("mission_slots.create", errors: @slot.errors), status: :bad_request
        end
      end

      def update
        authorize_slot!(@slot, @slot.slottable)

        if @slot.update(slot_attrs)
          render :show
        else
          render json: ValidationError.new("mission_slots.update", errors: @slot.errors), status: :bad_request
        end
      end

      def destroy
        authorize_slot!(@slot, @slot.slottable)

        unless @slot.destroy
          render json: ValidationError.new("mission_slots.destroy", errors: @slot.errors), status: :bad_request
        end
      end

      def sort
        slottable = find_slottable(params[:slottable_type], params[:slottable_id])
        return render json: {code: "not_found"}, status: :not_found unless slottable

        authorize_slot!(slottable, slottable, to: :sort?)

        sorting = params.permit(sorting: [])[:sorting] || []

        MissionSlot.transaction do
          sorting.each_with_index do |id, index|
            slottable.mission_slots.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def slot_attrs
        authorized(params, with: MissionSlotPolicy)
          .except(:slottable_type, :slottable_id)
      end

      # The seams a flight's slots override, like the ones on the ship
      # controller.
      private def authorize_slot!(record, slottable, to: nil)
        authorize!(record, with: MissionSlotPolicy, context: {mission: slottable.mission}, **(to ? {to:} : {}))
      end

      private def require_events_subscription
        require_fleet_subscription(:events)
      end

      private def set_slottable
        @slottable = find_slottable(params[:slottable_type], params[:slottable_id])
        raise ActiveRecord::RecordNotFound, "slottable not found" unless @slottable
      end

      private def set_slot
        @slot = MissionSlot.find(params[:id])
      end

      private def find_slottable(type, id)
        case type
        when "MissionTeam" then MissionTeam.find_by(id: id)
        when "MissionShip" then MissionShip.find_by(id: id)
        end
      end

      private def next_position
        (@slottable.mission_slots.maximum(:position) || -1) + 1
      end

      # `sort` loads neither of the callbacks above -- it resolves the slottable
      # inside the action -- so without the third arm every sort would reach the
      # concern with no fleet and skip enforcement entirely. Non-raising, so a
      # bad slottable still gets the action's own 404 rather than a different one.
      private def subscription_fleet
        slottable = @slottable || @slot ||
          find_slottable(params[:slottable_type], params[:slottable_id])

        slottable&.mission&.fleet
      end

      private def check_fleet_mission_builder_feature
        # Slots are addressed directly, without a fleet in the path, so the
        # actor comes off whichever record this action loaded.
        fleet = (@slottable || @slot)&.mission&.fleet
        return if feature_enabled?("fleet_mission_builder", fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
