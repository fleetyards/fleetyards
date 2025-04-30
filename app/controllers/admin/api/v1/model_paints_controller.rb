# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelPaintsController < ::Admin::Api::BaseController
        def index
          authorize! with: ::Admin::ModelPaintPolicy

          model_paint_query_params["sorts"] ||= sorting_params(ModelPaint, "created_at desc")

          @q = authorized_scope(ModelPaint.all).ransack(model_paint_query_params)

          @model_paints = @q.result
            .page(params[:page])
            .per(per_page(ModelPaint))
        end

        private def model_paint_query_params
          @model_paint_query_params ||= query_params(
            :name_in, :id_eq, :name_cont, :name_eq
          )
        end
      end
    end
  end
end
