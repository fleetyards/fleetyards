# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class MissionSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: Mission::ALLOWED_SORTING_PARAMS,
          "x-enumNames": Mission::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
