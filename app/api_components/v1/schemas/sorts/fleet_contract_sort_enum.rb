# frozen_string_literal: true

module V1
  module Schemas
    module Sorts
      class FleetContractSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::FleetContract::ALLOWED_SORTING_PARAMS,
          "x-enumNames": ::FleetContract::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
