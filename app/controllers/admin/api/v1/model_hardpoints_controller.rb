# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelHardpointsController < ::Admin::Api::BaseController
        before_action :set_model_hardpoint, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ModelHardpointPolicy

          hardpoint_query_params["sorts"] = "name asc"

          @q = authorized_scope(ModelHardpoint.includes(:component)).ransack(hardpoint_query_params)

          @model_hardpoints = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_hardpoint = ModelHardpoint.new(hardpoint_params)

          authorize! @model_hardpoint, with: ::Admin::ModelHardpointPolicy

          if @model_hardpoint.save
            render :show, status: :created
          else
            render json: ValidationError.new("model_hardpoint.create", errors: @model_hardpoint.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_hardpoint.update(hardpoint_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_hardpoint.update", errors: @model_hardpoint.errors), status: :bad_request
          end
        end

        def destroy
          @model_hardpoint.destroy

          head :no_content
        end

        private def set_model_hardpoint
          @model_hardpoint = ModelHardpoint.find(params[:id])

          authorize! @model_hardpoint, with: ::Admin::ModelHardpointPolicy
        end

        private def hardpoint_params
          @hardpoint_params ||= params.permit(
            :name, :source, :key, :hardpoint_type, :group, :category, :sub_category,
            :size, :details, :mount, :item_slots, :loadout_identifier,
            :component_id, :model_id
          )
        end

        private def hardpoint_query_params
          @hardpoint_query_params ||= params.permit(q: [
            :model_id_eq, :group_eq, :hardpoint_type_eq, :source_eq, :name_cont, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
