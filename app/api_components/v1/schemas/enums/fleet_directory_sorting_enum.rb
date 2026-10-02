# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What the fleet directory may be ordered by, sourced from the model so
      # the schema cannot drift from what `sorting_params` accepts.
      class FleetDirectorySortingEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Fleet::DIRECTORY_SORTING_PARAMS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
