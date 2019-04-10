# frozen_string_literal: true

module Api
  module V1
    class RoadmapController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: %i[]

      def index
        authorize! :index, :api_roadmap

        roadmap_query_params['sorts'] = ['release asc', 'name asc']

        @q = RoadmapItem.ransack(roadmap_query_params)

        @roadmap_items = @q.result
      end

      private def roadmap_query_params
        @roadmap_query_params ||= query_params(
          :name_cont, :released_eq, rsi_category_id_in: [], sorts: []
        )
      end
    end
  end
end
