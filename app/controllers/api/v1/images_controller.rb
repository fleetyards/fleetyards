# frozen_string_literal: true

module Api
  module V1
    class ImagesController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      after_action -> { pagination_header(:images) }, only: [:index]

      def index
        scope = Image.enabled
          .global_enabled
          .order("images.created_at desc")

        q = scope.ransack(image_query_params)

        @images = q.result
          .page(params[:page])
          .per(per_page(Image))
      end

      def random
        limit_filter = (1..100).cover?(params[:limit].to_i) ? params[:limit].to_i : 14

        @images = Image.enabled
          .global_enabled
          .in_gallery
          .includes(:gallery)
          .order(Arel.sql("RANDOM()"))
          .first(limit_filter)
      end

      private def image_query_params
        @image_query_params ||= params.permit(q: [
          model_in: [], station_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
