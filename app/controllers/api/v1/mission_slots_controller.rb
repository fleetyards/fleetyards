# frozen_string_literal: true

module Api
  module V1
    class MissionSlotsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?

      before_action :check_mission_builder_feature
      before_action :set_slottable, only: %i[create]
      before_action :set_slot, only: %i[update destroy]

      def create
        @slot = @slottable.mission_slots.new(slot_attrs)
        @slot.position = next_position

        authorize! @slot, with: MissionSlotPolicy, context: {mission: @slottable.mission}

        if @slot.save
          render :show, status: :created
        else
          render json: ValidationError.new("mission_slots.create", errors: @slot.errors), status: :bad_request
        end
      end

      def update
        authorize! @slot, with: MissionSlotPolicy, context: {mission: @slot.mission}

        if @slot.update(slot_attrs)
          render :show
        else
          render json: ValidationError.new("mission_slots.update", errors: @slot.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @slot, with: MissionSlotPolicy, context: {mission: @slot.mission}

        unless @slot.destroy
          render json: ValidationError.new("mission_slots.destroy", errors: @slot.errors), status: :bad_request
        end
      end

      def sort
        slottable = find_slottable(params[:slottable_type], params[:slottable_id])
        return render json: {code: "not_found"}, status: :not_found unless slottable

        authorize! slottable, with: MissionSlotPolicy, to: :sort?, context: {mission: slottable.mission}

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

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
