# frozen_string_literal: true

module Api
  module V1
    class ModelPaintsController < ::Api::BaseController
      skip_verify_authorized only: %i[index]

      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:paints) }, only: %i[index]

      def index
        scope = ModelPaint.visible.active

        model_paint_query_params["sorts"] = "name asc"

        @q = scope.ransack(model_paint_query_params)

        @paints = @q.result
          .page(params[:page])
          .per(per_page(ModelPaint))
      end

      private def model_paint_query_params
        @model_paint_query_params ||= params.permit(q: [
          :name_cont, :id_eq, :model_slug_eq,
          name_in: [], id_not_in: [], id_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
