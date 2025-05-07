# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ComponentsController < ::Admin::Api::BaseController
        skip_verify_authorized only: %i[class_filters item_type_filters]

        before_action :set_component, only: %i[show]

        def index
          authorize! with: ::Admin::ComponentPolicy

          component_query_params["sorts"] ||= sorting_params(Component)

          @q = authorized_scope(Component.all).includes(:manufacturer).ransack(component_query_params)

          @components = @q.result
            .page(params[:page])
            .per(per_page(Component))
        end

        def show
        end

        def class_filters
          @filters = Component.class_filters

          render "api/shared/filters"
        end

        def item_type_filters
          @filters = Component.item_type_filters

          render "api/shared/filters"
        end

        private def set_component
          @component = Component.find(params[:id])

          authorize! @component, with: ::Admin::ComponentPolicy
        end

        private def component_query_params
          @component_query_params ||= query_params(
            :name_in, :id_eq, :name_cont, :name_eq, :item_type_eq
          )
        end
      end
    end
  end
end
