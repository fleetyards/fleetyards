# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # What one contractor put into one line, and what that is worth when the
      # reward divides. `weight` is the line's own fraction; `FleetContractShare`
      # is the same measure rolled up across every line.
      class FleetContractContribution
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            userId: {type: :string, format: :uuid},
            delivered: {type: :string},
            weight: {type: :number}
          },
          additionalProperties: false,
          required: %w[userId delivered weight]
        })
      end
    end
  end
end
