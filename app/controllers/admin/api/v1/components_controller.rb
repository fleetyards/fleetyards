# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ComponentsController < ::Admin::Api::BaseController
        def index
          authorize! :index, :admin_api_components

          component_query_params['sorts'] = sort_by_name

          @q = Component.includes(:manufacturer).ransack(component_query_params)

          @components = @q.result
            .page(params[:page])
            .per(per_page(Component))
        end

        private def component_query_params
          @component_query_params ||= query_params(
            :name_in, :id_eq
          )
        end
      end
    end
  end
end
