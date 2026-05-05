# frozen_string_literal: true

module Api
  module V1
    class FleetEventSlotsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_slottable, only: %i[create]
      before_action :set_slot, only: %i[update destroy]

      def create
        @slot = @slottable.fleet_event_slots.new(slot_attrs)
        @slot.position = next_position

        authorize! @slot, with: FleetEventSlotPolicy, context: {fleet_event: @slottable.fleet_event}, to: :create?

        if @slot.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_event_slots.create", errors: @slot.errors), status: :bad_request
        end
      end

      def update
        authorize! @slot, with: FleetEventSlotPolicy, context: {fleet_event: @slot.fleet_event}, to: :update?

        if @slot.update(slot_attrs)
          render :show
        else
          render json: ValidationError.new("fleet_event_slots.update", errors: @slot.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @slot, with: FleetEventSlotPolicy, context: {fleet_event: @slot.fleet_event}, to: :destroy?

        unless @slot.destroy
          render json: ValidationError.new("fleet_event_slots.destroy", errors: @slot.errors), status: :bad_request
        end
      end

      def sort
        slottable = find_slottable(params[:slottable_type], params[:slottable_id])
        return render json: {code: "not_found"}, status: :not_found unless slottable

        authorize! slottable, with: FleetEventSlotPolicy, to: :sort?, context: {fleet_event: slottable.fleet_event}

        sorting = params.permit(sorting: [])[:sorting] || []

        FleetEventSlot.transaction do
          sorting.each_with_index do |id, index|
            slottable.fleet_event_slots.where(id: id).update_all(position: index)
          end
        end

        render json: {success: true}
      end

      private def slot_attrs
        authorized(params, with: FleetEventSlotPolicy)
          .except(:slottable_type, :slottable_id)
      end

      private def set_slottable
        @slottable = find_slottable(params[:slottable_type], params[:slottable_id])
        raise ActiveRecord::RecordNotFound, "slottable not found" unless @slottable
      end

      private def set_slot
        @slot = FleetEventSlot.find(params[:id])
      end

      private def find_slottable(type, id)
        case type
        when "FleetEventTeam" then FleetEventTeam.find_by(id: id)
        when "FleetEventShip" then FleetEventShip.find_by(id: id)
        end
      end

      private def next_position
        (@slottable.fleet_event_slots.maximum(:position) || -1) + 1
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
