# frozen_string_literal: true

module Api
  module V1
    class CelestialObjectsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:celestial_objects) }, only: [:index]

      def index
        authorize! :index, :api_celestial_objects

        celestial_object_query_params["sorts"] = sorting_params(CelestialObject)

        @q = CelestialObject.includes(:starsystem, :parent)
          .visible
          .ransack(celestial_object_query_params)

        @celestial_objects = @q.result(distinct: true)
          .page(params[:page])
          .per(per_page(CelestialObject))
      end

      def show
        authorize! :show, :api_celestial_objects

        @celestial_object = CelestialObject.visible.find_by!(slug: params[:slug])
      end

      private def celestial_object_query_params
        @celestial_object_query_params ||= begin
          permitted_query_params = query_params(
            :starsystem_eq, :main, :name_cont, :search_cont, :parent_eq, :parent_id_null,
            name_in: []
          )

          if permitted_query_params[:main].present?
            permitted_query_params.delete(:main)
            permitted_query_params[:parent_id_null] = true
          end

          permitted_query_params
        end
      end
    end
  end
end
