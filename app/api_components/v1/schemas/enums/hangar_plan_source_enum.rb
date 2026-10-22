# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HangarPlanSourceEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::HangarPlans::Builder::SOURCES,
          "x-enumNames": ::HangarPlans::Builder::SOURCES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
