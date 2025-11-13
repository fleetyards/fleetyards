# frozen_string_literal: true

module V1
  module Schemas
    class Stats
      include Rswag::SchemaComponents::Component

      schema({
        type: :object,
        properties: {
          shipsCountYear: {type: :integer},
          shipsCountTotal: {type: :integer}
        },
        additionalProperties: false,
        required: %w[shipsCountYear shipsCountTotal]
      })
    end
  end
end
