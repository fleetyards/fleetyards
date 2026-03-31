# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class OtpBackupCodes
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            codes: {
              type: :array,
              items: {type: :string},
              additionalProperties: false
            }
          },
          additionalProperties: false,
          required: %w[codes]
        })
      end
    end
  end
end
