# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            shortDescription: {type: [:string, :null]},
            description: {type: [:string, :null]},
            color: {type: [:string, :null]},
            team: {type: :boolean},
            discordChannelId: {type: [:string, :null]},
            icon: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
