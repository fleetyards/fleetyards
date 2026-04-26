# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelPositionsController < ::Admin::Api::BaseController
        before_action :set_model_position, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::ModelPositionPolicy

          model_position_query_params["sorts"] = "position asc"

          @q = authorized_scope(ModelPosition.all).ransack(model_position_query_params)

          @model_positions = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @model_position = ModelPosition.new(model_position_params)

          authorize! @model_position, with: ::Admin::ModelPositionPolicy

          if @model_position.save
            render :show, status: :created
          else
            render json: ValidationError.new("model_position.create", errors: @model_position.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @model_position.update(model_position_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_position.update", errors: @model_position.errors), status: :bad_request
          end
        end

        def destroy
          @model_position.destroy

          head :no_content
        end

        def regenerate
          authorize! with: ::Admin::ModelPositionPolicy

          model = Model.find(params[:model_id])
          ModelPosition.generate_for_model!(model)

          @model_positions = model.model_positions.order(position: :asc)
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))

          render :index
        end

        private def set_model_position
          @model_position = ModelPosition.find(params[:id])

          authorize! @model_position, with: ::Admin::ModelPositionPolicy
        end

        private def model_position_params
          @model_position_params ||= params.permit(
            :model_id, :name, :position_type, :hardpoint_id, :source, :position
          )
        end

        private def model_position_query_params
          @model_position_query_params ||= params.permit(q: [
            :model_id_eq, :position_type_eq, :source_eq, :name_cont, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
