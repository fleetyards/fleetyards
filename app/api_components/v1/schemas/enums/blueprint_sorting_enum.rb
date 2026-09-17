# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What a blueprint list may be ordered by. Inlined into `s` and `sorts`
      # this generated two anonymous types per query schema -- `BlueprintQueryS`
      # and `BlueprintQuerySortsItem` -- for one list of strings.
      #
      # Sourced from the model so the schema cannot drift from what
      # `sorting_params` actually accepts.
      class BlueprintSortingEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Blueprint::ALLOWED_SORTING_PARAMS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
