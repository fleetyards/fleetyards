# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index]

      after_action -> { pagination_header(:components) }, only: [:index]

      def index
        components_query_params["sorts"] = "name asc"

        @q = Component.includes(:manufacturer).ransack(components_query_params)

        @components = @q.result
          .page(params[:page])
          .per(per_page(Component))
      end

      private def components_query_params
        @components_query_params ||= query_params(
          :name_cont,
          id_in: [], name_in: [], item_type_in: [], manufacturer_slug_in: [], component_class_in: []
        )
      end
    end
  end
end
