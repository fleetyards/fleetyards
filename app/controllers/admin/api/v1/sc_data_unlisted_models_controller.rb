# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Ships the game files describe that Fleetyards has no model for.
      #
      # The rows are written by the sc_data load, never by hand, so there is no
      # create, update or destroy here -- only listing them and deciding.
      class ScDataUnlistedModelsController < ::Admin::Api::BaseController
        before_action :set_entry, only: %i[ignore create_model mark_as_paint reset]

        def index
          authorize! with: ::Admin::ScDataUnlistedModelPolicy

          query_params["sorts"] = sorting_params(ScDataUnlistedModel, query_params[:sorts])

          # Undecided by default, because that is the working list. An explicit
          # `decision` filter is what reaches the ones already dealt with.
          scope = ScDataUnlistedModel.includes(:model, base_model: :paints)
          scope = scope.undecided if query_params[:decision_eq].blank? && query_params[:decision_null].blank?

          @q = authorized_scope(scope).ransack(query_params)

          @sc_data_unlisted_models = @q.result
            .page(params[:page])
            .per(per_page(ScDataUnlistedModel))
        end

        # Not a ship somebody owns: an NPC copy the marker filter missed, a prop,
        # a template. It stops being reported and stays recorded, so the next
        # load does not raise it again.
        def ignore
          @sc_data_unlisted_model.decide!("ignored")
        end

        # It belongs on an existing model as a livery rather than as a model of
        # its own. Records the decision only -- a paint needs a name and artwork
        # an admin supplies, which is what the paints import already handles.
        def mark_as_paint
          @sc_data_unlisted_model.mark_as_paint!
        end

        def create_model
          @sc_data_unlisted_model.create_model!
        rescue ArgumentError => e
          # Put on the record rather than raised as a bare hash: `ValidationError`
          # reads `errors` off whatever it is given, so the two failure paths
          # below produce the same shape in the payload.
          @sc_data_unlisted_model.errors.add(:base, e.message)

          render json: ValidationError.new(
            "sc_data_unlisted_model.create_model", errors: @sc_data_unlisted_model.errors
          ), status: :bad_request
        rescue ActiveRecord::RecordInvalid => e
          render json: ValidationError.new(
            "sc_data_unlisted_model.create_model", errors: e.record.errors
          ), status: :bad_request
        end

        # For a decision made in error. The model a `create_model` left behind
        # stays: deleting a ship is its own action, and a hangar entry may
        # already point at it.
        def reset
          @sc_data_unlisted_model.reset!
        end

        private def set_entry
          @sc_data_unlisted_model = ScDataUnlistedModel.find(params[:id])

          authorize! @sc_data_unlisted_model, with: ::Admin::ScDataUnlistedModelPolicy
        end

        private def query_params
          @query_params ||= params.permit(q: [
            :sorts, :identifier_cont, :name_cont, :comparison_eq, :decision_eq,
            :decision_null, :manufacturer_code_eq
          ]).fetch(:q, {})
        end
      end
    end
  end
end
