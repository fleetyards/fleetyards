# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelPaintsController < ::Admin::Api::BaseController
        def index
          authorize! :index, :admin_api_model_paints

          model_paint_query_params['sorts'] = sort_by_name

          @q = ModelPaint.ransack(model_paint_query_params)

          @model_paints = @q.result
            .page(params[:page])
            .per(per_page(ModelPaint))
        end

        private def model_paint_query_params
          @model_paint_query_params ||= query_params(
            :name_in, :id_eq
          )
        end
      end
    end
  end
end
