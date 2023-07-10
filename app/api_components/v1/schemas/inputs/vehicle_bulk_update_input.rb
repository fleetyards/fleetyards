# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class VehicleBulkUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            ids: {type: :array, items: {type: :string, format: :uuid}},
            wanted: {type: :boolean, nullable: true},
            public: {type: :boolean, nullable: true},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}, nullable: true}
          },
          additionalProperties: false,
          required: %w[ids]
        })
      end
    end
  end
end
