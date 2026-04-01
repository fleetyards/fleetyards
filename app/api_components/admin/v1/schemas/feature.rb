# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Feature
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            state: {type: :string},
            selfService: {type: :boolean},
            percentageOfActors: {type: :number},
            percentageOfTime: {type: :number},
            groups: {type: :array, items: {type: :string}},
            actors: {type: :array, items: {"$ref": "#/components/schemas/FeatureActor"}}
          },
          additionalProperties: false,
          required: %w[name state selfService percentageOfActors percentageOfTime groups actors]
        })
      end
    end
  end
end
