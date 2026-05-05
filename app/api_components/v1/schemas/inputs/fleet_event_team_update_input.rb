# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetEventTeamUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            title: {type: :string},
            description: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
