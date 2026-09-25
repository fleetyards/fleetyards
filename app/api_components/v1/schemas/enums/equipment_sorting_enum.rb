# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What an equipment list may be ordered by. Sourced from the model so the
      # schema cannot drift from what `sorting_params` actually accepts.
      class EquipmentSortingEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Equipment::ALLOWED_SORTING_PARAMS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
