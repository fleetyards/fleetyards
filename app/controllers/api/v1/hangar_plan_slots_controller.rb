# frozen_string_literal: true

module Api
  module V1
    class HangarPlanSlotsController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan
      before_action :set_slot, only: %i[update destroy choose]

      def create
        @slot = @hangar_plan.slots.new(slot_params)

        if @slot.save
          render_hangar_plan(status: :created)
        else
          render json: ValidationError.new("hangar_plan_slots.create", errors: @slot.errors), status: :bad_request
        end
      end

      def update
        if @slot.update(slot_params)
          render_hangar_plan
        else
          render json: ValidationError.new("hangar_plan_slots.update", errors: @slot.errors), status: :bad_request
        end
      end

      def destroy
        @slot.destroy!

        render_hangar_plan
      end

      def sort
        ids = Array(params[:sorting])

        HangarPlanSlot.transaction do
          ids.each_with_index do |id, index|
            @hangar_plan.slots.where(id:).update_all(position: index, updated_at: Time.current)
          end
          @hangar_plan.touch
        end

        render_hangar_plan
      end

      # Keeps one candidate and drops the rest, together with any routes the
      # dropped ones had.
      def choose
        candidate = @slot.candidates.find(params[:candidate_id])

        HangarPlanSlot.transaction do
          @slot.candidates.where.not(id: candidate.id).destroy_all
          @slot.touch
        end

        render_hangar_plan
      end

      private def set_slot
        @slot = @hangar_plan.slots.find(params[:id])
      end

      # A sent filter set replaces the stored one whole, so an empty one clears it.
      private def slot_params
        permitted = params.permit(:label, :quantity, :description)
        return permitted unless params.key?(:filters)

        list_filters = HangarPlanSlot::LIST_FILTERS.index_with { [] }
        scalar_filters = HangarPlanSlot::NUMBER_FILTERS + HangarPlanSlot::BOOLEAN_FILTERS
        filters = params.fetch(:filters, nil)
        permitted.merge(filters: filters.respond_to?(:permit) ? filters.permit(*scalar_filters, **list_filters).to_h : {})
      end
    end
  end
end
