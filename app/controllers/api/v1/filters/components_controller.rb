# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ComponentsController < ::Api::PublicBaseController
        skip_verify_authorized

        def categories
          @filters = Component.category_filters

          render "api/v1/shared/filters"
        end

        def sub_types
          @filters = Component.sub_type_filters(category: params[:category])

          render "api/v1/shared/filters"
        end

        def sizes
          @filters = Component.size_filters(categories: requested_categories)

          render "api/v1/shared/filters"
        end

        def grades
          @filters = Component.grade_filters(categories: requested_categories)

          render "api/v1/shared/filters"
        end

        private def requested_categories
          Array(params.dig(:q, :category_in)).map(&:to_s)
        end
      end
    end
  end
end
