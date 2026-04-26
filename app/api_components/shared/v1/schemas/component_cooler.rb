# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentCooler
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            coolingRate: {type: :number}
          },
          additionalProperties: false,
          required: %w[coolingRate]
        })
      end
    end
  end
end
