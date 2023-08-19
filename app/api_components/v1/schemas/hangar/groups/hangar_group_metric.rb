# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Groups
        class HangarGroupMetric
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slug: {type: :string},
              count: {type: :integer}
            },
            additionalProperties: false,
            required: %w[id slug count]
          })
        end
      end
    end
  end
end
