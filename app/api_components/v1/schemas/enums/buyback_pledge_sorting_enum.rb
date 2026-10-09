# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class BuybackPledgeSortingEnum
        include OpenapiRuby::Components::Base

        VALUES = ::BuybackPledge::ALLOWED_SORTING_PARAMS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
