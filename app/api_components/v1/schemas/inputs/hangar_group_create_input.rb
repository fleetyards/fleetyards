# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarGroupCreateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            color: {type: :string},
            sort: {type: :integer, nullable: true},
            public: {type: :boolean, nullable: true}
          },
          additionalProperties: false,
          required: %w[name color]
        })
      end
    end
  end
end
