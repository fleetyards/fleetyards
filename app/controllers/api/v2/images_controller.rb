# frozen_string_literal: true

module Api
  module V2
    class ImagesController < ::Api::V2::BaseController
      before_action :authenticate_user!, only: []

      def index
        authorize! :index, :api_images

        @images = Image.enabled
          .global_enabled
          .in_gallery
          .with_uniq_name
          .order('images.created_at desc')
          .page(params[:page])
          .per(per_page(Image))
      end

      def random
        authorize! :index, :api_images
        
        @images = Image.enabled
          .global_enabled
          .in_gallery
          .with_uniq_name
          .includes(:gallery)
          .order(Arel.sql('RANDOM()'))
          .first(14)
      end
    end
  end
end
