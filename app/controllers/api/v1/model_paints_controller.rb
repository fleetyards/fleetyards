# frozen_string_literal: true

module Api
  module V1
    class ModelPaintsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:paints) }, only: %i[index]

      def index
        authorize! :index, :api_models

        scope = ModelPaint.visible.active

        model_paint_query_params["sorts"] = sort_by_name

        @q = scope.ransack(model_paint_query_params)

        @paints = @q.result
          .page(params[:page])
          .per(per_page(ModelPaint))
      end

      private def model_paint_query_params
        @model_paint_query_params ||= query_params(
          :name_cont, :id_eq, :model_slug_eq,
          name_in: [], id_not_in: [], id_in: []
        )
      end
    end
  end
end
