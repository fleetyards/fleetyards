# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class BoughtViaEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Vehicle.bought_via.keys,
            "x-enumNames": ::Vehicle.bought_via.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
