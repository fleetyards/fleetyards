# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class HangarGroupUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string, nullable: true},
            color: {type: :string, nullable: true},
            sort: {type: :integer, nullable: true},
            public: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
