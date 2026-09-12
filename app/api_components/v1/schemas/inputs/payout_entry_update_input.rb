# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PayoutEntryUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            payoutParticipantId: {type: :string, format: :uuid},
            entryType: ::V1::Schemas::Enums::PayoutEntryTypeEnum,
            amount: {type: [:string, :number]},
            description: {type: :string},
            notes: {type: [:string, :null]},
            occurredAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
