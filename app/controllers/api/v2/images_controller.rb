# frozen_string_literal: true

module Api
  module V2
    class ImagesController < ::Api::V2::BaseController
      before_action :authenticate_user!, only: []

      def index
        authorize! :index, :api_images

        scope = Image.enabled
          .global_enabled
          .in_gallery
          .with_uniq_name
          .includes(:gallery)

        scope = if params[:randomOrder]
                  scope.order(Arel.sql("RANDOM()"))
                else
                  scope.order("images.created_at desc")
                end

        @images = scope
          .page(params[:page])
          .per(per_page(Image))
      end
    end
  end
end
