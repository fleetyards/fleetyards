# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # The catalogue entry a line points at, when it points at one. Optional
      # by design: the line is matched to deposits by name, category and unit,
      # so a hand-typed delivery of the right goods still counts.
      class FleetContractItemRef
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            type: {type: :string},
            name: {type: :string},
            slug: {type: [:string, :null]}
          },
          additionalProperties: false,
          required: %w[id type name]
        })
      end
    end
  end
end
