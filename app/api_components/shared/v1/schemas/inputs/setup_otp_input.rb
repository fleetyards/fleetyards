# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Inputs
        class SetupOtpInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              otpCode: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
