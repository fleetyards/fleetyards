# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class AdminUserInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              username: {type: :string},
              email: {type: :string},
              password: {type: :string},
              passwordConfirmation: {type: :string},
              superAdmin: {type: :boolean},
              resourceAccess: {type: :array, items: {type: :string}}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
