# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetActivityCategoryEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Fleets::ActivityFeed::CATEGORIES

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
