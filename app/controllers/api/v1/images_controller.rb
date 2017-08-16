# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ImagesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action only: [:index] { pagination_header(:images) }

      def index
        authorize! :index, :api_images
        @images = Image.enabled
                       .in_gallery
                       .order("images.created_at desc")
                       .page(params.fetch(:page, nil))
                       .per(params.fetch(:perPage, nil))
      end

      def latest
        authorize! :index, :api_images
        @images = Image.enabled.in_gallery.order("RANDOM()").limit(14)
      end
    end
  end
end
