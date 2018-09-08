# frozen_string_literal: true

module Api
  module V1
    class ImagesController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:images) }, only: [:index]

      def index
        authorize! :index, :api_images
        @images = Image.enabled
                       .in_gallery
                       .with_uniq_name
                       .order('images.created_at desc')
                       .page(params[:page])
                       .per([(params[:per_page] || Image.default_per_page), Image.default_per_page * 4].min)
      end

      def random
        authorize! :index, :api_images
        @images = Image.enabled
                       .in_gallery
                       .with_uniq_name
                       .order(Arel.sql('RANDOM()'))
                       .first(16)
      end
    end
  end
end
