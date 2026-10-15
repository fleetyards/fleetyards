# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class VehicleLoadoutKindEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::VehicleLoadout.kinds.values,
          "x-enumNames": ::VehicleLoadout.kinds.values.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
