# frozen_string_literal: true

module Api
  module V1
    module Filters
      class ComponentsController < ::Api::PublicBaseController
        def classes
          @class_filters = Component.class_filters
        end

        def item_types
          @item_type_filters = Component.item_type_filters
        end
      end
    end
  end
end
