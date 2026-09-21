# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetSquadronCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            description: {type: [:string, :null]},
            color: {type: [:string, :null]},
            logo: {type: [:string, :null]}
          },
          required: %w[name],
          additionalProperties: false
        })
      end
    end
  end
end
