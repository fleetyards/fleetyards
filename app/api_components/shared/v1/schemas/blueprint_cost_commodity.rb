# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The material a cost line resolves to. Null where the commodity
      # catalogue has no row for it, which is what `commodityKey` still
      # answers.
      class BlueprintCostCommodity
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
