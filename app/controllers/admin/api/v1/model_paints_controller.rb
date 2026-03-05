# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelPaintsController < ::Admin::Api::BaseController
        before_action :set_model_paint, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::ModelPaintPolicy

          model_paint_query_params["sorts"] = sorting_params(ModelPaint, model_paint_query_params[:sorts], "created_at desc")

          @q = authorized_scope(ModelPaint.all).ransack(model_paint_query_params)

          @model_paints = @q.result
            .page(params[:page])
            .per(per_page(ModelPaint))
        end

        def show
        end

        def create
          @model_paint = ModelPaint.new(model_paint_params)

          authorize! @model_paint, with: ::Admin::ModelPaintPolicy

          return if @model_paint.save

          render json: ValidationError.new("model_paint.create", errors: @model_paint.errors), status: :bad_request
        end

        def update
          return if @model_paint.update(model_paint_params)

          render json: ValidationError.new("model_paint.update", errors: @model_paint.errors), status: :bad_request
        end

        def destroy
          return if @model_paint.destroy

          render json: ValidationError.new("model_paint.destroy", errors: @model_paint.errors), status: :bad_request
        end

        private def set_model_paint
          @model_paint = ModelPaint.find(params[:id])

          authorize! @model_paint, with: ::Admin::ModelPaintPolicy
        end

        private def model_paint_params
          @model_paint_params ||= params.permit(
            :name, :description, :model_id, :active, :hidden, :on_sale,
            :pledge_price, :production_status, :production_note, :store_url,
            :store_image, :rsi_store_image, :fleetchart_image,
            :top_view, :side_view, :angled_view
          )
        end

        private def model_paint_query_params
          @model_paint_query_params ||= params.permit(q: [
            :name_in, :id_eq, :name_cont, :name_eq, :model_id_eq, :sorts,
            sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
