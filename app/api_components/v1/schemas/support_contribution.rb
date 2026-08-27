# frozen_string_literal: true

module V1
  module Schemas
    class SupportContribution
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          displayName: {type: :string},
          username: {type: :string},
          amountCents: {type: :integer},
          currency: {type: :string},
          recurring: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[displayName amountCents currency recurring]
      })
    end
  end
end
