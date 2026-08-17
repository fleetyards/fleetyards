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
          @filters = Equipment.item_type_filters(equipment_types)

          render "api/v1/shared/filters"
        end

        private def equipment_types
          Array(params.dig(:q, :equipment_type_in)).map(&:to_s) & Equipment::EQUIPMENT_TYPES
        end
      end
    end
  end
end
