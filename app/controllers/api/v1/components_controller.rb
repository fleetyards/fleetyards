# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def categories
        authorize! :show, :api_components
        @categories = ComponentCategory.all
      end
    end
  end
end
