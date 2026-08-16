# frozen_string_literal: true

module Api
  module V1
    module Filters
      class EquipmentController < ::Api::PublicBaseController
        skip_verify_authorized

        def types
          @filters = Equipment.type_filters

          render "api/v1/shared/filters"
        end

        def item_types
          @filters = Equipment.item_type_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
