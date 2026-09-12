# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class InventoryTransferReportInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            reason: ::V1::Schemas::Enums::InventoryTransferReportReasonEnum,
            note: {type: :string}
          },
          additionalProperties: false,
          required: %w[reason]
        })
      end
    end
  end
end
