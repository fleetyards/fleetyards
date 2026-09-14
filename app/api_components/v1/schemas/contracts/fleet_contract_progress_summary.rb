# frozen_string_literal: true

module V1
  module Schemas
    module Contracts
      # One bar's worth of progress, for a board. The contract's own page reads
      # `FleetContractProgress`, which carries the lines and the shares.
      class FleetContractProgressSummary
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fraction: {type: :number},
            delivered: {type: :string},
            requested: {type: :string},
            # Null when the lines are measured in different units, which is what
            # tells a client to show the share rather than a quantity.
            unit: {type: [:string, :null]},
            complete: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[fraction delivered requested complete]
        })
      end
    end
  end
end
