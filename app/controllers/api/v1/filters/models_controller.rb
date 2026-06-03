# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ModelsController < ::Api::PublicBaseController
        skip_verify_authorized

        def production_states
          @filters = Model.production_status_filters

          render "api/v1/shared/filters"
        end

        def classifications
          @filters = Model.classification_filters

          render "api/v1/shared/filters"
        end

        def focus
          @filters = Model.focus_filters

          render "api/v1/shared/filters"
        end

        def sizes
          @filters = Model.size_filters

          render "api/v1/shared/filters"
        end

        def dock_sizes
          @filters = Model.dock_size_filters

          render "api/v1/shared/filters"
        end

        def index
          @filters ||= begin
            filters = []
            filters << Manufacturer.model_filters
            filters << Model.production_status_filters
            filters << Model.classification_filters
            filters << Model.focus_filters
            filters << Model.size_filters
            filters.flatten
              .sort_by { |filter| [filter.category, filter.label] }
          end

          render "api/v1/shared/filters"
        end

        def options
          normalize_sort_params(model_query_params)
          model_query_params["sorts"] = sorting_params(Model, model_query_params["sorts"])

          @q = Model.visible.active.ransack(model_query_params)

          @models = result_with_pagination(@q.result, per_page(Model))
        end

        private def model_query_params
          @model_query_params ||= params.permit(
            q: [
              :name_cont, :name_eq, :slug_eq, :s, :sorts,
              name_in: [], slug_in: [], id_in: []
            ]
          )[:q].presence || {}
        end
      end
    end
  end
end
