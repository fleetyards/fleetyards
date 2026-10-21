# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarBlueprintMissions < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/HangarBlueprintMission"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
