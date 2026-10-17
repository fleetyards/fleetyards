# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class VehicleLoadoutItemProblemEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::VehicleLoadout::ITEM_PROBLEMS,
          "x-enumNames": ::VehicleLoadout::ITEM_PROBLEMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
