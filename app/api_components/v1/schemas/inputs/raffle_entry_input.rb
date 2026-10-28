# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RaffleEntryInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            conditionsAccepted: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[conditionsAccepted]
        })
      end
    end
  end
end
