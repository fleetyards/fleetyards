# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ImagesController < ::Api::BaseController
      before_action :authenticate_user!, only: []

      def latest
        authorize! :index, :api_ships
        @images = Image.enabled.order("RANDOM()").limit(14)
      end
    end
  end
end
