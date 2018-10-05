# frozen_string_literal: true

module Api
  module V1
    class PlanetsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def index
        authorize! :index, :api_planets
        @q = Planet.visible
                   .ransack(query_params)

        @q.sorts = 'name asc' if @q.sorts.empty?

        @planets = @q.result
                     .page(params[:page])
                     .per(per_page(Planet))
      end
    end
  end
end
