# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      after_action -> { pagination_header(:components) }, only: [:index]

      def index
        authorize! :index, :api_components

        components_query_params["sorts"] = sort_by_name

        @q = Component.includes(:manufacturer).ransack(components_query_params)

        @components = @q.result
          .page(params[:page])
          .per(per_page(Component))
      end

      def class_filters
        authorize! :index, :api_components
        @class_filters = Component.class_filters
      end

      def item_type_filters
        authorize! :index, :api_components
        @item_type_filters = Component.item_type_filters
      end

      private def components_query_params
        @components_query_params ||= query_params(:name_cont, id_in: [], name_in: [])
      end
    end
  end
end
