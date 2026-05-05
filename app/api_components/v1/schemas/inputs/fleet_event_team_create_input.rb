# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventTeamCreateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string, nullable: true}
          },
          required: %w[title],
          additionalProperties: false
        })
      end
    end
  end
end
