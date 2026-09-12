# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      # What one participant paid, what they are holding, the share they are
      # entitled to, and the difference. A positive net means they owe.
      class PayoutBalance
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            participant: PayoutParticipant,
            paid: {type: :string},
            held: {type: :string},
            share: {type: :string},
            net: {type: :string}
          },
          required: %w[participant paid held share net],
          additionalProperties: false
        })
      end
    end
  end
end
