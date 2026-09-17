# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # How a recipe is handed out: "contract" is a mission an org offers,
        # "scenario" is XenoThreat handing pools out by progress points.
        class BlueprintSourceKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::BlueprintSource::KINDS

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
