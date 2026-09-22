# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class GameMissions < ::Shared::V1::Schemas::BaseList
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            items: {type: :array, items: {"$ref": "#/components/schemas/GameMission"}}
          },
          required: %w[items]
        })
      end
    end
  end
end
