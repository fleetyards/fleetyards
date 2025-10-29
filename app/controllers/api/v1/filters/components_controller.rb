# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ComponentsController < ::Api::PublicBaseController
        skip_verify_authorized

        def classes
          @filters = Component.class_filters

          render "api/v1/shared/filters"
        end

        def item_types
          @filters = Component.item_type_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
