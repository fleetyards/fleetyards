# frozen_string_literal: true

module Api
  module V1
    class CelestialObjectsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:celestial_objects) }, only: [:index]

      def index
        authorize! :index, :api_celestial_objects

        @celestial_objects = CelestialObject.search(
          search_params || '*',
          fields: [{ name: :word_start }],
          where: query_params.merge({ visible: true }),
          order: sort_params,
          page: params[:page],
          per_page: per_page(CelestialObject),
          includes: %i[starsystem parent]
        )
      end

      def show
        authorize! :show, :api_celestial_objects

        @celestial_object = CelestialObject.visible.find_by!(slug: params[:slug])
      end

      private def search_params
        @search_params ||= params.permit(:search)[:search]
      end

      private def query_params
        @query_params ||= begin
          permitted_params = params.permit(
            q: [
              :main, { name: [], starsystem: [], parent: [] }
            ]
          )

          permitted_params[:q] || {}
        end
      end

      private def sort_params
        @sort_params ||= begin
          permitted_params = params.permit(
            sort: [
              :parent,
              :designation,
              :name
            ]
          )

          permitted_params[:sort] || {
            parent: { order: :desc, missing: :_first },
            designation: :asc
          }
        end
      end
    end
  end
end
