# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []
      after_action -> { pagination_header(:components) }, only: [:index]

      def index
        authorize! :index, :api_components

        components_query_params['sorts'] = sort_by_name

        @q = Component.ransack(components_query_params)

        @components = @q.result
                        .page(params[:page])
                        .per(per_page(Component))
      end

      private def components_query_params
        @components_query_params ||= query_params
      end
    end
  end
end
