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
          @filters = Equipment.item_type_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def sub_types
          @filters = Equipment.sub_type_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def weapon_classes
          @filters = Equipment.weapon_class_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def slots
          @filters = Equipment.slot_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def sizes
          @filters = Equipment.size_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def grades
          @filters = Equipment.grade_filters(narrowing)

          render "api/v1/shared/filters"
        end

        def manufacturers
          @filters = Equipment.manufacturer_filters(narrowing)

          render "api/v1/shared/filters"
        end

        private def narrowing
          {
            equipment_type: query_values(:equipment_type_in) & Equipment::EQUIPMENT_TYPES,
            sub_type: query_values(:sub_type_in),
            slot: query_values(:slot_in) & EquipmentBuild.slots.keys,
            size: query_values(:size_in)
          }.compact_blank
        end

        private def query_values(key)
          Array(params.dig(:q, key)).map(&:to_s)
        end
      end
    end
  end
end
