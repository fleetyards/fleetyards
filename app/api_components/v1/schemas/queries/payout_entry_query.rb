# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class PayoutEntryQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            descriptionCont: {type: :string},
            entryTypeEq: ::V1::Schemas::Enums::PayoutEntryTypeEnum,
            reviewStatusEq: ::V1::Schemas::Enums::PayoutEntryReviewStatusEnum,
            payoutParticipantIdEq: {type: :string, format: :uuid},
            s: {type: :string}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
