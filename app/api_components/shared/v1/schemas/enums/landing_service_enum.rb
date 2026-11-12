# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class LandingServiceEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ModelBuild::LANDING_SERVICES

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
