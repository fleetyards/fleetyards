# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      class HangarClassificationMetric
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            label: {type: :string},
            count: {type: :integer}
          },
          additionalProperties: false,
          required: %w[name label count]
        })
      end
    end
  end
end
