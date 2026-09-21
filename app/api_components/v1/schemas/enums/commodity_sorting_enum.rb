# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What a commodity list may be ordered by. A component rather than an
      # inline enum for the reason `BlueprintSortingEnum` names: inlined into
      # `s` and `sorts` it generates two anonymous types per query schema for
      # one list of strings.
      #
      # Sourced from the model so the schema cannot drift from what
      # `sorting_params` actually accepts.
      class CommoditySortingEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Commodity::ALLOWED_SORTING_PARAMS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
