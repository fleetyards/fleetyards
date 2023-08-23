# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Groups
        class HangarGroupPublic
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              color: {type: :string},
              sort: {type: :integer},
              vehiclesCount: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug color createdAt updatedAt]
          })
        end
      end
    end
  end
end
