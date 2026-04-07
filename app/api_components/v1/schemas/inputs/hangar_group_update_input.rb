# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarGroupUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            color: {type: :string},
            sort: {type: :integer, nullable: true},
            public: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
